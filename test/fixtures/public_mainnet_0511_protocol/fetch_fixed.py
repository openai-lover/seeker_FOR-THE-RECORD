from pathlib import Path
import datetime,json,hashlib,time,urllib.request,urllib.error,email.utils
W=Path(__file__).parent
P=json.loads((W/'protocol.json').read_text(encoding='utf-8'))
PH=hashlib.sha256((W/'protocol.json').read_bytes()).hexdigest()
assert PH==(W/'protocol.sha256').read_text().split()[0]
assert P['protocolId'].endswith('v2')
assert not (W/'fetch-receipt.json').exists(), 'No overwrite/re-run'
(W/'raw').mkdir(exist_ok=True)
def utc():return datetime.datetime.now(datetime.timezone.utc).isoformat()
receipt={'protocolSha256':PH,'scope':P['scope'],'rpc':P['rpc'],'startedAtUtc':utc(),'requests':[],'epochs':[],'rows':[]}
last_start=0.;req_id=0

def save():
 (W/'fetch-receipt.json').write_text(json.dumps(receipt,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')

def retry_after_seconds(value):
 if value is None:return None
 try:return max(0,float(value))
 except ValueError:
  try:return max(0,(email.utils.parsedate_to_datetime(value)-datetime.datetime.now(datetime.timezone.utc)).total_seconds())
  except Exception:return None

def rpc(label,method,params):
 global last_start,req_id
 req_id+=1;body=json.dumps({'jsonrpc':'2.0','id':req_id,'method':method,'params':params}).encode()
 item={'requestId':req_id,'label':label,'method':method,'params':params,'requestSha256':hashlib.sha256(body).hexdigest(),'attempts':[]}
 receipt['requests'].append(item)
 for at in range(2):
  pause=2-(time.monotonic()-last_start)
  if pause>0:time.sleep(pause)
  last_start=time.monotonic();started=utc();status=None;raw=b'';transport=None;retryafter=None
  req=urllib.request.Request(P['rpc'],data=body,headers={'Content-Type':'application/json'},method='POST')
  try:
   with urllib.request.urlopen(req,timeout=25) as resp:
    status=resp.status;raw=resp.read();retryafter=resp.headers.get('Retry-After')
  except urllib.error.HTTPError as e:
   status=e.code;raw=e.read();retryafter=e.headers.get('Retry-After')
  except Exception as e:transport=type(e).__name__+': '+str(e)
  path=W/'raw'/f'{label}-attempt{at+1}.json'
  path.write_bytes(raw)
  record={'attempt':at+1,'startedAtUtc':started,'completedAtUtc':utc(),'httpStatus':status,'responseFile':str(path.relative_to(W)).replace('\\','/'),'responseBytes':len(raw),'responseSha256':hashlib.sha256(raw).hexdigest(),'retryAfter':retryafter,'transportError':transport}
  try:parsed=json.loads(raw.decode('utf-8'))
  except Exception as e:parsed=None;record['decodeError']=type(e).__name__
  record['rpcError']=parsed.get('error') if isinstance(parsed,dict) else None
  item['attempts'].append(record);save()
  retryable=(transport is not None or status==429 or (status is not None and status>=500))
  delay=retry_after_seconds(retryafter)
  if at==0 and retryable and (delay is None or delay<=10):
   record['retryDelaySeconds']=10;save();time.sleep(10);continue
  item['chosenAttempt']=at+1;item['httpOk']=status==200
  item['rpcOk']=status==200 and isinstance(parsed,dict) and parsed.get('error') is None and 'result' in parsed
  save();return parsed if item['rpcOk'] else None,item
 raise AssertionError('bounded attempts exhausted')

anchor_utc=datetime.datetime.now(datetime.timezone.utc);anchor_mono=time.monotonic()
receipt['epoch0AnchorUtc']=anchor_utc.isoformat();save()
seen={}
for e,offset in enumerate(P['epochOffsetsSeconds']):
 while time.monotonic()<anchor_mono+offset:
  time.sleep(min(1,anchor_mono+offset-time.monotonic()))
 epoch={'epoch':e,'targetAtUtc':(anchor_utc+datetime.timedelta(seconds=offset)).isoformat(),'startedAtUtc':utc(),'programs':[]}
 receipt['epochs'].append(epoch);save()
 for prog in P['programs']:
  name=prog['name'];env,lr=rpc(f'e{e}-{name}-list','getSignaturesForAddress',[prog['address'],P['listingParams']])
  infos=env.get('result') if isinstance(env,dict) else None
  group={'program':name,'address':prog['address'],'listRequestId':lr['requestId'],'listingAvailable':isinstance(infos,list),'returnedPositions':len(infos) if isinstance(infos,list) else 0}
  epoch['programs'].append(group);save()
  for rank in range(P['signaturesPerProgramEpoch']):
   case=f'e{e}-{name}-{rank}'
   row={'caseId':case,'epoch':e,'program':name,'rank':rank,'listRequestId':lr['requestId'],'selectionInfo':infos[rank] if isinstance(infos,list) and rank<len(infos) else None}
   receipt['rows'].append(row);info=row['selectionInfo']
   if not isinstance(info,dict) or not isinstance(info.get('signature'),str):
    row['fetchState']='listing-unavailable' if not group['listingAvailable'] else 'missing-or-malformed-list-position';save();continue
   sig=info['signature'];row['duplicateOf']=seen.get(sig);seen.setdefault(sig,case)
   env,tr=rpc(case,'getTransaction',[sig,P['transactionParams']]);row['transactionRequestId']=tr['requestId']
   if env is None:row['fetchState']='transaction-request-error'
   elif env.get('result') is None:row['fetchState']='transaction-null'
   else:row['fetchState']='transaction-available'
   row['transactionFile']=tr['attempts'][tr['chosenAttempt']-1]['responseFile'];save()
 epoch['completedAtUtc']=utc();save()
 print(json.dumps({'epoch':e,'completedAtUtc':epoch['completedAtUtc'],'positionsSoFar':len(receipt['rows']),'states':{state:sum(r.get('fetchState')==state for r in receipt['rows'] if r['epoch']==e) for state in sorted(set(r.get('fetchState') for r in receipt['rows'] if r['epoch']==e))}}),flush=True)
receipt['completedAtUtc']=utc();receipt['uniqueSignatures']=len(seen);receipt['duplicateSelectionPositions']=sum(r.get('duplicateOf') is not None for r in receipt['rows']);save()
print(json.dumps({'completedAtUtc':receipt['completedAtUtc'],'selectionPositions':len(receipt['rows']),'uniqueSignatures':len(seen),'requests':len(receipt['requests'])}),flush=True)
