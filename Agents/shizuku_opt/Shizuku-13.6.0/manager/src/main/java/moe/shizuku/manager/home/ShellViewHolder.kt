package moe.shizuku.manager.home

import android.content.Intent
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import moe.shizuku.manager.R
import moe.shizuku.manager.databinding.HomeItemContainerBinding
import moe.shizuku.manager.databinding.HomeShellBinding
import moe.shizuku.manager.shell.ShellActivity
import rikka.recyclerview.BaseViewHolder
import rikka.recyclerview.BaseViewHolder.Creator

class ShellViewHolder(private val binding: HomeShellBinding, private val root: View) :
    BaseViewHolder<Any?>(root), View.OnClickListener {

    companion object {
        val CREATOR = Creator<Any> { inflater: LayoutInflater, parent: ViewGroup? ->
            val outer = HomeItemContainerBinding.inflate(inflater, parent, false)
            val inner = HomeShellBinding.inflate(inflater, outer.root, true)
            ShellViewHolder(inner, outer.root)
        }
    }

    init {
        root.setOnClickListener(this)
    }

    override fun onBind() {
        // No special state needed for placeholder
    }

    override fun onClick(v: View) {
        v.context.startActivity(Intent(v.context, ShellActivity::class.java))
    }
}
