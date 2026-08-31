<script setup>
import { Handle, Position } from '@vue-flow/core';

defineProps({
  data: { type: Object, required: true },
  selected: { type: Boolean, default: false },
});
</script>

<template>
  <article
    class="w-64 rounded-2xl border bg-n-background shadow-2xl transition"
    :class="
      selected ? 'border-n-brand ring-2 ring-brand/20' : 'border-n-strong'
    "
  >
    <header class="flex items-center gap-3 border-b border-n-weak px-4 py-3">
      <span
        class="flex size-9 items-center justify-center rounded-xl bg-violet-500/15 text-violet-400"
      >
        <span class="i-lucide-zap size-4" />
      </span>
      <div>
        <p
          class="text-[10px] font-semibold uppercase tracking-wider text-violet-400"
        >
          {{ $t('FLOW_BUILDER.NODE.TRIGGER') }}
        </p>
        <h3 class="text-sm font-medium text-n-slate-12">{{ data.label }}</h3>
      </div>
    </header>
    <div class="px-4 py-3 text-xs text-n-slate-11">
      <p v-if="data.mode === 'keywords'">
        {{
          data.keywords?.length
            ? `${data.keywords.length} كلمات مفتاحية`
            : $t('FLOW_BUILDER.NODE.ADD_KEYWORDS')
        }}
      </p>
      <p v-else>{{ $t('FLOW_BUILDER.NODE.NO_MATCH_DESCRIPTION') }}</p>
    </div>
    <Handle
      type="source"
      :position="Position.Right"
      class="!size-3 !border-2 !border-black !bg-violet-500"
    />
  </article>
</template>
