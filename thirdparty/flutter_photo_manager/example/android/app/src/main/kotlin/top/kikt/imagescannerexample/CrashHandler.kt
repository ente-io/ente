package top.kikt.imagescannerexample

import android.annotation.SuppressLint
import android.content.Context
import android.util.Log
import java.io.BufferedWriter
import java.io.File
import java.io.PrintWriter
import java.text.SimpleDateFormat
import java.util.*

/// create 2019/2/18 by cai
@SuppressLint("StaticFieldLeak")
object CrashHandler : Thread.UncaughtExceptionHandler {

    private var defaultHandler: Thread.UncaughtExceptionHandler? = null
    private lateinit var context: Context

    private var df = SimpleDateFormat("yyyy-MM-dd", Locale.CHINA)
    private var timeDf = SimpleDateFormat("hh:mm:ss", Locale.CHINA)

    override fun uncaughtException(t: Thread, e: Throwable) {


        val file = context.externalCacheDir?.absoluteFile ?: return

        val dt = df.format(Date())
        val fileName = "${file.absolutePath}/$dt.log"

        Log.w("CrashTag", "output: $fileName")

        var writer: BufferedWriter? = null
        var printWriter: PrintWriter? = null
        try {
            writer = File(fileName).outputStream().bufferedWriter()
            writer.write(getTimeString())
            writer.newLine()
            printWriter = PrintWriter(writer)
            e.printStackTrace(printWriter)
            writer.newLine()
            writer.write("------------")
            writer.newLine()
            writer.newLine()
        } finally {
            printWriter?.close()
            writer?.close()
        }

        defaultHandler?.uncaughtException(t, e)
    }

    private fun getTimeString(): String {
        return timeDf.format(Date())
    }

    fun initHandler(context: Context) {
        this.context = context
        defaultHandler = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler(this)
    }
}