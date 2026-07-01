package moe.shizuku.manager.debloat.ui

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import com.google.android.material.bottomsheet.BottomSheetDialogFragment
import com.google.android.material.chip.Chip
import moe.shizuku.manager.R
import moe.shizuku.manager.databinding.BottomSheetFilterBinding
import moe.shizuku.manager.debloat.data.PackageClassification

class FilterBottomSheet : BottomSheetDialogFragment() {

    private var _binding: BottomSheetFilterBinding? = null
    private val binding get() = _binding!!

    private var onApply: ((Set<PackageClassification>) -> Unit)? = null

    companion object {
        fun newInstance(onApply: (Set<PackageClassification>) -> Unit): FilterBottomSheet {
            return FilterBottomSheet().apply {
                this.onApply = onApply
            }
        }
    }

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        _binding = BottomSheetFilterBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val chips = mapOf(
            binding.chipRecommended to PackageClassification.RECOMMENDED,
            binding.chipAdvanced to PackageClassification.ADVANCED,
            binding.chipExpert to PackageClassification.EXPERT,
            binding.chipUnsafe to PackageClassification.UNSAFE,
            binding.chipDisabled to PackageClassification.DISABLED,
            binding.chipSystem to PackageClassification.SYSTEM,
            binding.chipUser to PackageClassification.USER
        )

        binding.btnApply.setOnClickListener {
            val selected = chips.filter { it.key.isChecked }.map { it.value }.toSet()
            onApply?.invoke(selected)
            dismiss()
        }

        binding.btnClear.setOnClickListener {
            chips.keys.forEach { it.isChecked = false }
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
