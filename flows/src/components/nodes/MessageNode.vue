<script setup>
import { computed } from 'vue';
import { Handle, Position } from '@vue-flow/core';

const props = defineProps({
  data: { type: Object, required: true },
  selected: { type: Boolean, default: false },
  nodeType: { type: String, required: true },
});

const config = computed(
  () =>
    ({
      text: {
        label: 'رسالة نصية',
        icon: 'i-lucide-text',
        color: 'text-sky-400 bg-sky-500/15',
      },
      image: {
        label: 'صورة',
        icon: 'i-lucide-image',
        color: 'text-emerald-400 bg-emerald-500/15',
      },
      video: {
        label: 'فيديو',
        icon: 'i-lucide-video',
        color: 'text-amber-400 bg-amber-500/15',
      },
      document: {
        label: 'مستند PDF',
        icon: 'i-lucide-file-text',
        color: 'text-rose-400 bg-rose-500/15',
      },
    })[props.nodeType]
);

const preview = computed(() => {
  if (props.nodeType === 'text')
    return props.data.content || 'اكتب محتوى الرسالة';
  return (
    props.data.caption ||
    props.data.filename ||
    props.data.url ||
    'أضف تفاصيل الوسائط'
  );
});
</script>

<template>
  <article
    class="w-64 rounded-2xl border bg-n-background shadow-2xl transition"
    :class="
      selected ? 'border-n-brand ring-2 ring-brand/20' : 'border-n-strong'
    "
  >
    <Handle
      type="target"
      :position="Position.Left"
      class="!size-3 !border-2 !border-black !bg-n-slate-8"
    />
    <header class="flex items-center gap-3 border-b border-n-weak px-4 py-3">
      <span
        class="flex size-9 items-center justify-center rounded-xl"
        :class="config.color"
      >
        <span class="size-4" :class="[config.icon]" />
      </span>
      <div>
        <p
          class="text-[10px] font-semibold uppercase tracking-wider text-n-slate-10"
        >
          {{ $t('FLOW_BUILDER.NODE.MESSAGE') }}
        </p>
        <h3 class="text-sm font-medium text-n-slate-12">{{ config.label }}</h3>
      </div>
    </header>
    <p
      class="line-clamp-2 min-h-14 px-4 py-3 text-xs leading-5 text-n-slate-11"
    >
      {{ preview }}
    </p>
    <Handle
      type="source"
      :position="Position.Right"
      class="!size-3 !border-2 !border-black !bg-n-brand"
    />
  </article>
</template>
