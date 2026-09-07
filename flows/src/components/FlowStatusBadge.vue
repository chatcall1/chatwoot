<script setup>
import { computed } from 'vue';

const props = defineProps({ status: { type: String, required: true } });
const options = {
  draft: {
    label: 'مسودة',
    classes: 'bg-n-alpha-2 text-n-slate-11',
    icon: 'i-lucide-file-pen-line',
  },
  published: {
    label: 'منشور',
    classes: 'bg-n-teal-3 text-n-teal-11',
    icon: 'i-lucide-circle-check',
  },
  archived: {
    label: 'معطّل',
    classes: 'bg-n-amber-3 text-n-amber-11',
    icon: 'i-lucide-circle-pause',
  },
};
const option = computed(() => options[props.status] || options.draft);
</script>

<template>
  <span
    class="inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-medium"
    :class="option.classes"
  >
    <span class="size-3.5" :class="option.icon" />
    {{ option.label }}
  </span>
</template>
