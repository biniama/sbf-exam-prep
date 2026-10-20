package ai.biniam.sbfexamprep

import android.app.Application
import ai.biniam.sbfexamprep.audio.SoundSignalPlayer
import ai.biniam.sbfexamprep.data.ProgressRepository
import ai.biniam.sbfexamprep.data.QuestionRepository
import kotlinx.coroutines.MainScope

class SbfApplication : Application() {
    val questions: QuestionRepository by lazy {
        assets.open(QuestionRepository.ASSET_NAME).use { QuestionRepository.load(it) }
    }
    val progressRepository: ProgressRepository by lazy { ProgressRepository(this) }
    val soundPlayer: SoundSignalPlayer by lazy { SoundSignalPlayer(MainScope()) }
}
