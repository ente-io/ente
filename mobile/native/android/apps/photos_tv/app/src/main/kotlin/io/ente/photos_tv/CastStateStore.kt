package io.ente.photos_tv

import android.content.Context
import androidx.datastore.core.CorruptionException
import androidx.datastore.core.Serializer
import androidx.datastore.dataStore
import kotlinx.coroutines.flow.first
import kotlinx.serialization.Serializable
import kotlinx.serialization.SerializationException
import kotlinx.serialization.encodeToString
import java.io.InputStream
import java.io.OutputStream

private const val CAST_STATE_FILE_NAME = "photos_tv_cast_state.json"

private val Context.castStateDataStore by dataStore(
    fileName = CAST_STATE_FILE_NAME,
    serializer = CastStateSerializer,
)

@Serializable
internal data class CastState(
    val payload: CastPayload? = null,
)

internal class CastStateStore(context: Context) {
    private val dataStore = context.applicationContext.castStateDataStore
    var state = CastState()
        private set

    suspend fun load() {
        state = dataStore.data.first()
    }

    suspend fun save(value: CastState) {
        state = dataStore.updateData { value }
    }

    suspend fun clear() {
        state = dataStore.updateData { CastState() }
    }
}

private object CastStateSerializer : Serializer<CastState> {
    override val defaultValue = CastState()

    override suspend fun readFrom(input: InputStream): CastState {
        return try {
            val bytes = input.readBytes()
            if (bytes.isEmpty()) defaultValue else JsonConfig.value.decodeFromString(bytes.decodeToString())
        } catch (error: SerializationException) {
            throw CorruptionException("Cannot read cast state", error)
        }
    }

    override suspend fun writeTo(t: CastState, output: OutputStream) {
        output.write(JsonConfig.value.encodeToString(t).encodeToByteArray())
    }
}
