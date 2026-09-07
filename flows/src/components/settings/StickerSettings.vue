<script setup>
import Switch from 'dashboard/components-next/switch/Switch.vue';
import MediaSettings from './MediaSettings.vue';

const props = defineProps({ data: { type: Object, required: true } });
const emit = defineEmits(['update']);
const animatedLabel = 'ملصق متحرك';
const sizeHelp = 'الحد الأقصى: 100KB للثابت و500KB للمتحرك.';
const patch = changes => emit('update', { ...props.data, ...changes });
</script>

<template>
  <MediaSettings
    :data="data"
    node-type="sticker"
    :show-caption="false"
    @update="$emit('update', $event)"
  />
  <div class="flex items-center gap-3">
    <Switch
      :model-value="Boolean(data.animated)"
      @update:model-value="patch({ animated: $event })"
    />
    <span class="text-sm text-n-slate-12">{{ animatedLabel }}</span>
  </div>
  <p class="text-xs text-n-slate-10">{{ sizeHelp }}</p>
</template>
