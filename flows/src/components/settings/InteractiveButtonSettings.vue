<script setup>
import Input from 'dashboard/components-next/input/Input.vue';

const props = defineProps({ data: { type: Object, required: true } });
const emit = defineEmits(['update']);
const patch = changes => emit('update', { ...props.data, ...changes });
const completionHint =
  'اربط النقطة السفلية برسالة تالية حتى يصبح مسار الزر مكتملًا.';
</script>

<template>
  <Input
    :model-value="data.title"
    label="عنوان الزر"
    maxlength="20"
    @update:model-value="patch({ title: $event })"
  />
  <Input
    :model-value="data.replyId"
    label="معرّف الرد"
    maxlength="256"
    custom-input-class="direction-ltr text-left"
    @update:model-value="patch({ replyId: $event })"
  />
  <p class="text-xs text-n-slate-10">{{ completionHint }}</p>
</template>
