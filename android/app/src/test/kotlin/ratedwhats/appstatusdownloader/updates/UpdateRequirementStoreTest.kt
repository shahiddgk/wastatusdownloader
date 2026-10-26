package ratedwhats.appstatusdownloader.updates

import android.content.SharedPreferences
import java.lang.reflect.Proxy
import org.junit.Assert.*
import org.junit.Test

class UpdateRequirementStoreTest {
    @Test
    fun immediateUpdateResultHandlesAllActivityOutcomes() {
        assertEquals("success", immediateUpdateResult(-1))
        assertEquals("cancelled", immediateUpdateResult(0))
        assertEquals("failed", immediateUpdateResult(1))
        assertEquals("failed", immediateUpdateResult(999))
    }

    @Test
    fun requirementPersistsAcrossStoreInstancesAndNeverDowngrades() {
        val preferences = MemoryPreferences()
        val store = UpdateRequirementStore(preferences.instance)
        assertNull(store.read())
        store.write(20L)
        UpdateRequirementStore(preferences.instance).write(18L)
        assertEquals(20L, UpdateRequirementStore(preferences.instance).read())
        store.write(21L)
        assertEquals(21L, store.read())
    }

    @Test
    fun explicitNullClearsSatisfiedRequirement() {
        val store = UpdateRequirementStore(MemoryPreferences().instance)
        store.write(20L)
        store.write(null)
        assertNull(store.read())
    }

    @Test
    fun failedDurableCommitIsReportedToCaller() {
        val preferences = MemoryPreferences()
        val store = UpdateRequirementStore(preferences.instance)
        store.write(20L)
        preferences.commitSucceeds = false
        assertThrows(IllegalStateException::class.java) { store.write(21L) }
        assertEquals(20L, store.read())
        assertThrows(IllegalStateException::class.java) { store.write(null) }
    }

    @Test
    fun onlyPositiveIntegerVersionCodesOrExplicitNullAreAccepted() {
        assertNull(parseRequiredVersionCode(null))
        assertEquals(16L, parseRequiredVersionCode(16))
        assertEquals(3_000_000_000L, parseRequiredVersionCode(3_000_000_000L))
        for (invalid in listOf(0, -1, 0L, -1L, 16.0, "16", true)) {
            assertThrows(IllegalArgumentException::class.java) {
                parseRequiredVersionCode(invalid)
            }
        }
        val store = UpdateRequirementStore(MemoryPreferences().instance)
        assertThrows(IllegalArgumentException::class.java) { store.write(0L) }
        assertThrows(IllegalArgumentException::class.java) { store.write(-1L) }
    }

    private class MemoryPreferences {
        var commitSucceeds = true
        private val values = mutableMapOf<String, Long>()

        val instance: SharedPreferences = Proxy.newProxyInstance(
            SharedPreferences::class.java.classLoader,
            arrayOf(SharedPreferences::class.java),
        ) { _, method, arguments ->
            when (method.name) {
                "contains" -> values.containsKey(arguments!![0] as String)
                "getLong" -> values[arguments!![0] as String] ?: arguments[1]
                "edit" -> editor()
                else -> throw UnsupportedOperationException(method.name)
            }
        } as SharedPreferences

        private fun editor(): SharedPreferences.Editor {
            val pending = mutableMapOf<String, Long?>()
            return Proxy.newProxyInstance(
                SharedPreferences.Editor::class.java.classLoader,
                arrayOf(SharedPreferences.Editor::class.java),
            ) { proxy, method, arguments ->
                when (method.name) {
                    "putLong" -> {
                        pending[arguments!![0] as String] = arguments[1] as Long
                        proxy
                    }
                    "remove" -> {
                        pending[arguments!![0] as String] = null
                        proxy
                    }
                    "commit" -> {
                        if (commitSucceeds) {
                            for ((key, value) in pending) {
                                if (value == null) values.remove(key) else values[key] = value
                            }
                        }
                        commitSucceeds
                    }
                    else -> throw UnsupportedOperationException(method.name)
                }
            } as SharedPreferences.Editor
        }
    }
}
