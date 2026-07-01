package moe.shizuku.manager.debloat.ui

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import moe.shizuku.manager.R
import moe.shizuku.manager.databinding.ItemDebloatPackageBinding
import moe.shizuku.manager.debloat.data.DebloatPackage
import moe.shizuku.manager.debloat.data.PackageClassification

class DebloatAdapter(
    private val onItemClick: (DebloatPackage) -> Unit,
    private val onCheckboxClick: (DebloatPackage, Boolean) -> Unit,
    private val onLongClick: (DebloatPackage) -> Unit
) : ListAdapter<DebloatPackage, DebloatAdapter.ViewHolder>(DiffCallback) {

    private var isBatchMode = false
    private val selectedPackages = mutableSetOf<String>()

    object DiffCallback : DiffUtil.ItemCallback<DebloatPackage>() {
        override fun areItemsTheSame(oldItem: DebloatPackage, newItem: DebloatPackage): Boolean {
            return oldItem.packageName == newItem.packageName
        }

        override fun areContentsTheSame(oldItem: DebloatPackage, newItem: DebloatPackage): Boolean {
            return oldItem == newItem
        }
    }

    inner class ViewHolder(private val binding: ItemDebloatPackageBinding) :
        RecyclerView.ViewHolder(binding.root) {

        fun bind(pkg: DebloatPackage) {
            binding.apply {
                appIcon.setImageDrawable(pkg.icon ?: root.context.getDrawable(R.drawable.ic_default_app_icon_background))
                appName.text = pkg.appName
                packageName.text = pkg.packageName

                // Classification badge
                val badgeText = when (pkg.classification) {
                    PackageClassification.RECOMMENDED -> "RECOMMENDED"
                    PackageClassification.ADVANCED -> "ADVANCED"
                    PackageClassification.EXPERT -> "EXPERT"
                    PackageClassification.UNSAFE -> "UNSAFE"
                    PackageClassification.DISABLED -> "DISABLED"
                    PackageClassification.SYSTEM -> "SYSTEM"
                    PackageClassification.USER -> "USER"
                    else -> "UNKNOWN"
                }
                classificationBadge.text = badgeText

                val badgeColor = when (pkg.classification) {
                    PackageClassification.RECOMMENDED -> R.color.badge_recommended
                    PackageClassification.ADVANCED -> R.color.badge_advanced
                    PackageClassification.EXPERT -> R.color.badge_expert
                    PackageClassification.UNSAFE -> R.color.badge_unsafe
                    PackageClassification.DISABLED -> R.color.badge_disabled
                    PackageClassification.SYSTEM -> R.color.badge_system
                    PackageClassification.USER -> R.color.badge_user
                    else -> R.color.badge_unknown
                }
                classificationBadge.setBackgroundResource(badgeColor)

                checkbox.isChecked = selectedPackages.contains(pkg.packageName)
                checkbox.visibility = if (isBatchMode) android.view.View.VISIBLE else android.view.View.GONE

                root.setOnClickListener {
                    if (isBatchMode) {
                        checkbox.isChecked = !checkbox.isChecked
                        onCheckboxClick(pkg, checkbox.isChecked)
                    } else {
                        onItemClick(pkg)
                    }
                }

                root.setOnLongClickListener {
                    onLongClick(pkg)
                    true
                }

                checkbox.setOnCheckedChangeListener { _, isChecked ->
                    if (isBatchMode) {
                        onCheckboxClick(pkg, isChecked)
                    }
                }
            }
        }
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val binding = ItemDebloatPackageBinding.inflate(
            LayoutInflater.from(parent.context), parent, false
        )
        return ViewHolder(binding)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        holder.bind(getItem(position))
    }

    fun setBatchMode(batchMode: Boolean) {
        isBatchMode = batchMode
        notifyDataSetChanged()
    }

    fun updateSelection(packageName: String, selected: Boolean) {
        if (selected) {
            selectedPackages.add(packageName)
        } else {
            selectedPackages.remove(packageName)
        }
        notifyDataSetChanged()
    }
}
