package moe.shizuku.manager.home

import android.content.Intent
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import moe.shizuku.manager.R
import moe.shizuku.manager.databinding.HomeItemContainerBinding
import moe.shizuku.manager.databinding.HomeDebloatBinding
import moe.shizuku.manager.debloat.DebloatActivity
import rikka.recyclerview.BaseViewHolder
import rikka.recyclerview.BaseViewHolder.Creator

class DebloatViewHolder(private val binding: HomeDebloatBinding, private val root: View) :
    BaseViewHolder<Any?>(root), View.OnClickListener {

    companion object {
        val CREATOR = Creator<Any> { inflater: LayoutInflater, parent: ViewGroup? ->
            val outer = HomeItemContainerBinding.inflate(inflater, parent, false)
            val inner = HomeDebloatBinding.inflate(inflater, outer.root, true)
            DebloatViewHolder(inner, outer.root)
        }
    }

    init {
        root.setOnClickListener(this)
    }

    override fun onBind() {
        // No special state needed for placeholder
    }

    override fun onClick(v: View) {
        v.context.startActivity(Intent(v.context, DebloatActivity::class.java))
    }
}
