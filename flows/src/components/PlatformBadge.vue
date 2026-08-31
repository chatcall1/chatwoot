<script setup>
import { computed } from 'vue';
import { PLATFORM_OPTIONS } from '../domain/constants';

const props = defineProps({ platform: { type: String, required: true } });
const option = computed(() =>
  PLATFORM_OPTIONS.find(item => item.id === props.platform)
);
</script>

<template>
  <span
    class="inline-flex items-center gap-1.5 rounded-full border border-n-weak bg-n-alpha-2 px-2 py-1 text-xs text-n-slate-11"
  >
    <span class="size-3.5" :class="[option.icon]" />
    {{ option.label }}
  </span>
</template>
