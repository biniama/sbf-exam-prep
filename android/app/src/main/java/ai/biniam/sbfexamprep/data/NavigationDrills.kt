package ai.biniam.sbfexamprep.data

import ai.biniam.sbfexamprep.R
import java.util.Locale
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.roundToInt
import kotlin.random.Random

/** A light character such as "Oc(3).Y.12s", turned into on/off phases for the animation. */
class LightCharacter private constructor(val code: String, val colour: Char, val phases: List<Pair<Boolean, Double>>) {
    val period: Double get() = phases.sumOf { it.second }

    /** Short notation for display: "Oc(3) Y 12s". */
    val notation: String get() = code.replace('.', ' ')

    val kind: String get() = code.substringBefore('.').takeWhile { it.isLetter() }

    /** Whether the light is on [t] seconds into the cycle. */
    fun isOn(t: Double): Boolean {
        var remaining = t % max(period, 0.1)
        for ((on, seconds) in phases) {
            if (remaining < seconds) return on
            remaining -= seconds
        }
        return phases.lastOrNull()?.first ?: false
    }

    override fun equals(other: Any?) = other is LightCharacter && other.code == code
    override fun hashCode() = code.hashCode()

    /** String resource describing the rhythm. */
    val descriptionRes: Int
        get() = when (kind) {
            "F" -> R.string.light_fixed
            "Fl" -> R.string.light_flashing
            "LFl" -> R.string.light_long_flashing
            "Iso" -> R.string.light_isophase
            "Oc" -> R.string.light_occulting
            "Q" -> R.string.light_quick
            "VQ" -> R.string.light_very_quick
            "IQ" -> R.string.light_interrupted_quick
            else -> R.string.light_morse
        }

    companion object {
        /** Characters used by the light drill (including the cardinal marks). */
        val drillCodes = listOf(
            "F.R", "Fl.W.5s", "Fl(2).R.6s", "LFl.W.10s", "Iso.W.8s", "Iso.W.4s", "Oc.G.4s", "Oc(2).G.9s",
            "Oc(3).Y.12s", "Q.W", "Q(3).W.10s", "Q(9).W.15s", "VQ.W", "IQ.R.13s", "Mo(A).W.8s",
        )

        private val headPattern = Regex("^([A-Za-z]+)(?:\\((\\w+)\\))?$")
        private val morseTable = mapOf('A' to ".-", 'U' to "..-", 'D' to "-..", 'N' to "-.", 'K' to "-.-")

        /** Parses codes like "Fl.W.5s", "Q(3).W.10s", "IQ.R.13s", "Mo(A).W.8s", "F.G"; null if unknown. */
        fun parse(code: String): LightCharacter? {
            val parts = code.split('.')
            val m = headPattern.matchEntire(parts.first()) ?: return null
            val kind = m.groupValues[1]
            val group = m.groupValues[2].ifEmpty { null }
            val colour = parts.getOrNull(1)?.firstOrNull() ?: 'W'
            if (colour !in "WRGY") return null
            val period = parts.getOrNull(2)?.removeSuffix("s")?.toDoubleOrNull()
            val count = group?.toIntOrNull() ?: 1
            val phases = mutableListOf<Pair<Boolean, Double>>()
            fun flashes(n: Int, on: Double, off: Double, total: Double?) {
                repeat(n) { i ->
                    phases.add(true to on)
                    if (i < n - 1) phases.add(false to off)
                }
                val used = n * on + (n - 1) * off
                phases.add(false to max(off, (total ?: (used + off * 2)) - used))
            }
            when (kind) {
                "F" -> phases.add(true to 4.0)
                "Fl" -> flashes(count, 0.6, 1.0, period ?: 5.0)
                "LFl" -> flashes(count, 2.0, 1.5, period ?: 10.0)
                "Iso" -> { val p = period ?: 4.0; phases.add(true to p / 2); phases.add(false to p / 2) }
                "Oc" -> {
                    // Light longer than dark: short eclipses.
                    val p = period ?: 4.0
                    if (count == 1) {
                        phases.add(true to p - 1); phases.add(false to 1.0)
                    } else {
                        phases.add(true to p - count - (count - 1))
                        repeat(count) { i ->
                            phases.add(false to 1.0)
                            if (i < count - 1) phases.add(true to 1.0)
                        }
                    }
                }
                "Q" -> if (group?.toIntOrNull() != null) flashes(count, 0.3, 0.7, period) else { phases.add(true to 0.3); phases.add(false to 0.7) }
                "VQ" -> if (group?.toIntOrNull() != null) flashes(count, 0.2, 0.3, period) else { phases.add(true to 0.2); phases.add(false to 0.3) }
                "IQ" -> flashes(9, 0.3, 0.7, period ?: 13.0)
                "Mo" -> {
                    val symbols = (group ?: "A").mapNotNull { morseTable[it] }.joinToString("")
                    symbols.forEachIndexed { i, s ->
                        phases.add(true to if (s == '.') 0.5 else 1.5)
                        if (i < symbols.length - 1) phases.add(false to 0.5)
                    }
                    phases.add(false to max(1.0, (period ?: 8.0) - phases.sumOf { it.second }))
                }
                else -> return null
            }
            return LightCharacter(code, colour, phases)
        }
    }
}

/** Text that the UI turns into a string: a resource with arguments, or literal text (formulas). */
sealed interface DrillText {
    data class Res(val id: Int, val args: List<Any> = emptyList()) : DrillText
    data class Raw(val text: String) : DrillText
}

/** One randomly generated practice exercise with its worked solution. */
data class NavigationDrill(
    val kind: Kind,
    val prompt: DrillText,
    /** Unit next to the answer field (empty for multiple choice and clock times). */
    val unit: DrillText?,
    val solution: List<DrillText>,
    val answer: Double = 0.0,
    val tolerance: Double = 0.0,
    val isClock: Boolean = false,
    val light: LightCharacter? = null,
    val choices: List<LightCharacter> = emptyList(),
) {
    enum class Kind(val title: Int) {
        COURSE(R.string.drill_course), TIME_SPEED_DISTANCE(R.string.drill_tsd), ARRIVAL(R.string.drill_arrival),
        LIGHT(R.string.drill_light)
    }

    fun check(input: String): Boolean {
        if (isClock) {
            val given = NavigationAnswerChecker.clockMinutes(input) ?: return false
            return abs(given - answer) <= tolerance
        }
        val v = NavigationAnswerChecker.number(input) ?: return false
        return if (kind == Kind.COURSE) NavigationAnswerChecker.angleDifference(v, answer) <= tolerance
        else abs(v - answer) <= tolerance + 1e-9
    }

    fun check(choice: LightCharacter): Boolean = choice == light

    companion object {
        fun make(kind: Kind, random: Random = Random.Default): NavigationDrill = when (kind) {
            Kind.COURSE -> course(random)
            Kind.TIME_SPEED_DISTANCE -> timeSpeedDistance(random)
            Kind.ARRIVAL -> arrival(random)
            Kind.LIGHT -> lightDrill(random)
        }

        private fun norm(v: Int) = ((v % 360) + 360) % 360
        private fun deg(v: Int) = "%03d°".format(Locale.ROOT, norm(v))
        private fun signed(v: Int) = if (v == 0) "0°" else "%+d°".format(Locale.ROOT, v).replace('-', '−')
        private fun dec(v: Double) = if (v == v.roundToInt().toDouble()) "${v.roundToInt()}" else "%.1f".format(Locale.ROOT, v)
        private fun clock(m: Int) = "%02d:%02d".format(Locale.ROOT, (m / 60) % 24, m % 60)

        private fun course(r: Random): NavigationDrill {
            val mw = r.nextInt(-3, 4)
            val abl = r.nextInt(-8, 9)
            return when (r.nextInt(3)) {
                0 -> {
                    val rwk = r.nextInt(360); val mgk = norm(rwk - mw - abl)
                    NavigationDrill(Kind.COURSE, DrillText.Res(R.string.drill_course_t2c, listOf(deg(rwk), signed(mw), signed(abl))),
                        DrillText.Raw("°"), listOf(DrillText.Res(R.string.drill_course_t2c_rule),
                            DrillText.Raw("MgK = rwK − Mw − Abl = ${deg(rwk)} − (${signed(mw)}) − (${signed(abl)}) = ${deg(mgk)}")),
                        answer = mgk.toDouble())
                }
                1 -> {
                    val mgk = r.nextInt(360); val rwk = norm(mgk + abl + mw)
                    NavigationDrill(Kind.COURSE, DrillText.Res(R.string.drill_course_c2t, listOf(deg(mgk), signed(abl), signed(mw))),
                        DrillText.Raw("°"), listOf(DrillText.Res(R.string.drill_course_c2t_rule),
                            DrillText.Raw("rwK = MgK + Abl + Mw = ${deg(mgk)} + (${signed(abl)}) + (${signed(mw)}) = ${deg(rwk)}")),
                        answer = rwk.toDouble())
                }
                else -> {
                    val mgp = r.nextInt(360); val ablHand = if (r.nextBoolean()) 0 else abl; val rwp = norm(mgp + ablHand + mw)
                    NavigationDrill(Kind.COURSE, DrillText.Res(R.string.drill_course_bearing, listOf(deg(mgp), signed(ablHand), signed(mw))),
                        DrillText.Raw("°"), listOf(DrillText.Res(R.string.drill_course_bearing_rule),
                            DrillText.Raw("rwP = MgP + Abl + Mw = ${deg(mgp)} + (${signed(ablHand)}) + (${signed(mw)}) = ${deg(rwp)}")),
                        answer = rwp.toDouble())
                }
            }
        }

        private fun timeSpeedDistance(r: Random): NavigationDrill {
            val speed = r.nextInt(8, 25) / 2.0
            val minutes = r.nextInt(10, 121)
            val distance = (speed * minutes / 60 * 10).roundToInt() / 10.0
            return when (r.nextInt(3)) {
                0 -> {
                    val t = distance / speed * 60
                    NavigationDrill(Kind.TIME_SPEED_DISTANCE, DrillText.Res(R.string.drill_tsd_time, listOf(dec(distance), dec(speed))),
                        DrillText.Raw("min"), listOf(DrillText.Res(R.string.drill_tsd_time_rule),
                            DrillText.Raw("t = ${dec(distance)} ÷ ${dec(speed)} × 60 = ${dec((t * 10).roundToInt() / 10.0)} min")),
                        answer = t, tolerance = 1.0)
                }
                1 -> {
                    val v = distance / minutes * 60
                    NavigationDrill(Kind.TIME_SPEED_DISTANCE, DrillText.Res(R.string.drill_tsd_speed, listOf(dec(distance), minutes)),
                        DrillText.Raw("kn"), listOf(DrillText.Res(R.string.drill_tsd_speed_rule),
                            DrillText.Raw("v = ${dec(distance)} ÷ $minutes × 60 = ${dec((v * 10).roundToInt() / 10.0)} kn")),
                        answer = v, tolerance = 0.15)
                }
                else -> NavigationDrill(Kind.TIME_SPEED_DISTANCE, DrillText.Res(R.string.drill_tsd_distance, listOf(minutes, dec(speed))),
                    DrillText.Res(R.string.nav_unit_nm), listOf(DrillText.Res(R.string.drill_tsd_distance_rule),
                        DrillText.Raw("d = ${dec(speed)} × $minutes ÷ 60 = ${dec(distance)}")),
                    answer = distance, tolerance = 0.1)
            }
        }

        private fun arrival(r: Random): NavigationDrill {
            val start = r.nextInt(72, 205) * 5
            val speed = r.nextInt(8, 25) / 2.0
            val distance = r.nextInt(15, 151) / 10.0
            val minutes = (distance / speed * 60).roundToInt()
            val arrival = start + minutes
            return NavigationDrill(Kind.ARRIVAL, DrillText.Res(R.string.drill_arrival_prompt, listOf(clock(start), dec(distance), dec(speed))),
                null, listOf(DrillText.Res(R.string.drill_arrival_rule),
                    DrillText.Raw("t = ${dec(distance)} ÷ ${dec(speed)} × 60 ≈ $minutes min"),
                    DrillText.Raw("${clock(start)} + $minutes min = ${clock(arrival)}")),
                answer = arrival.toDouble(), tolerance = 1.0, isClock = true)
        }

        private fun lightDrill(r: Random): NavigationDrill {
            val all = LightCharacter.drillCodes.mapNotNull(LightCharacter::parse)
            val correct = all.random(r)
            // Wrong options get the same colour, so the rhythm has to be read, not the colour.
            val rhythm = { code: String -> code.substringBefore('.') }
            val seen = mutableSetOf(rhythm(correct.code))
            val others = mutableListOf<LightCharacter>()
            for (code in LightCharacter.drillCodes.shuffled(r)) {
                if (others.size == 3 || rhythm(code) in seen) continue
                val parts = code.split('.').toMutableList()
                if (parts.size > 1) parts[1] = correct.colour.toString()
                LightCharacter.parse(parts.joinToString("."))?.let { others.add(it); seen.add(rhythm(code)) }
            }
            return NavigationDrill(Kind.LIGHT, DrillText.Res(R.string.drill_light_prompt), null,
                listOf(DrillText.Raw(correct.notation + ":"), DrillText.Res(correct.descriptionRes)),
                light = correct, choices = (others + correct).shuffled(r))
        }
    }
}
