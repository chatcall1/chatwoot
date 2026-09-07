<script setup>
import Input from 'dashboard/components-next/input/Input.vue';
defineProps({ data: { type: Object, required: true } });
defineEmits(['update']);
const emojiLabel = 'رمز التفاعل';
const helpText = 'سيُضاف التفاعل إلى رسالة العميل التي شغّلت الفلو.';
</script>

<template>
  <Input
    :model-value="data.emoji"
    :label="emojiLabel"
    maxlength="16"
    @update:model-value="$emit('update', { ...data, emoji: $event })"
  />
  <p class="text-xs leading-5 text-n-slate-10">{{ helpText }}</p>
</template>
