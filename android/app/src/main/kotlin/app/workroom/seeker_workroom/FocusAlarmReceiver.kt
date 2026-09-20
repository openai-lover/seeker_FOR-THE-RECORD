package app.workroom.seeker_workroom

import android.Manifest
import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build

class FocusAlarmReceiver: BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if(Build.VERSION.SDK_INT>=33 && context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)!=PackageManager.PERMISSION_GRANTED)return
        val open=PendingIntent.getActivity(context,18,Intent(context,WorkroomActivity::class.java),PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val language = context.getSharedPreferences("record", Context.MODE_PRIVATE).getString("language", "en")
        val messages = mapOf(
            "en" to "Your focus time is complete. What did you move forward?",
            "ko" to "예정 시간이 끝났어요. 어떤 진전이 있었나요?",
            "ja" to "集中時間が終わりました。何が進みましたか？",
            "zh" to "专注时间已结束。你取得了哪些进展？",
            "hi" to "आपका ध्यान सत्र पूरा हुआ। आपने क्या प्रगति की?",
            "es" to "Tu sesión ha terminado. ¿En qué avanzaste?",
            "pt" to "Sua sessão terminou. Em que você avançou?",
            "fr" to "Votre séance est terminée. Quels progrès avez-vous faits ?"
        )
        val notification=Notification.Builder(context,"focus").setSmallIcon(R.drawable.ic_workroom).setContentTitle("FOR THE RECORD")
            .setContentText(messages[language] ?: messages["en"]).setContentIntent(open).setAutoCancel(true).build()
        context.getSystemService(NotificationManager::class.java).notify(17,notification)
    }
}
