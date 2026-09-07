<script setup>
import { computed } from 'vue';
import Input from 'dashboard/components-next/input/Input.vue';
import RadioCard from 'dashboard/components-next/radioCard/RadioCard.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import MediaSettings from './MediaSettings.vue';

const props = defineProps({ data: { type: Object, required: true } });
const emit = defineEmits(['update']);

const interactionTypeLabel = 'نوع التفاعل';
const headerTypeLabel = 'نوع الهيدر';
const interactionOptions = [
  {
    id: 'buttons',
    label: 'أزرار الرد',
    description: 'من زر واحد إلى ثلاثة أزرار',
  },
  {
    id: 'list',
    label: 'رسالة القائمة',
    description: 'قائمة تضم حتى عشرة صفوف',
  },
];
const buttonHeaderOptions = [
  { value: 'none', label: 'بدون هيدر' },
  { value: 'text', label: 'نص' },
  { value: 'image', label: 'صورة' },
  { value: 'video', label: 'فيديو' },
  { value: 'document', label: 'مستند' },
];
const listHeaderOptions = buttonHeaderOptions.slice(0, 2);

const headerMediaData = computed(() => ({
  blobSignedId: props.data.headerBlobSignedId || '',
  filename: props.data.headerFilename || '',
  contentType: props.data.headerContentType || '',
  byteSize: props.data.headerByteSize || 0,
}));

const patch = changes => emit('update', { ...props.data, ...changes });
const selectInteraction = interactionType => {
  const changes = { interactionType };
  if (
    interactionType === 'list' &&
    !['none', 'text'].includes(props.data.headerType)
  ) {
    Object.assign(changes, {
      headerType: 'none',
      headerBlobSignedId: '',
      headerFilename: '',
      headerContentType: '',
      headerByteSize: 0,
    });
  }
  patch(changes);
};

const selectHeaderType = headerType => {
  const changed = headerType !== props.data.headerType;
  patch({
    headerType,
    ...(changed && {
      headerBlobSignedId: '',
      headerFilename: '',
      headerContentType: '',
      headerByteSize: 0,
    }),
  });
};

const updateHeaderMedia = media =>
  patch({
    headerBlobSignedId: media.blobSignedId,
    headerFilename: media.filename,
    headerContentType: media.contentType,
    headerByteSize: media.byteSize,
  });
</script>

<template>
  <div class="space-y-2">
    <span class="flow-label">{{ interactionTypeLabel }}</span>
    <div class="grid grid-cols-2 gap-2">
      <RadioCard
        v-for="option in interactionOptions"
        :id="option.id"
        :key="option.id"
        name="interactive-type"
        :label="option.label"
        :description="option.description"
        :is-active="data.interactionType === option.id"
        class="!border-2 !p-3 !outline-none"
        :class="
          data.interactionType === option.id
            ? '!border-n-slate-12'
            : '!border-n-strong'
        "
        @select="selectInteraction"
      />
    </div>
  </div>

  <div class="space-y-2">
    <span class="flow-label">{{ headerTypeLabel }}</span>
    <Select
      :model-value="data.headerType"
      :options="
        data.interactionType === 'list'
          ? listHeaderOptions
          : buttonHeaderOptions
      "
      @update:model-value="selectHeaderType"
    />
  </div>

  <Input
    v-if="data.headerType === 'text'"
    :model-value="data.headerText"
    label="نص الهيدر"
    maxlength="60"
    @update:model-value="patch({ headerText: $event })"
  />
  <MediaSettings
    v-else-if="['image', 'video', 'document'].includes(data.headerType)"
    :data="headerMediaData"
    :node-type="data.headerType"
    :show-caption="false"
    @update="updateHeaderMedia"
  />

  <TextArea
    :model-value="data.body"
    label="نص الرسالة"
    :max-length="data.interactionType === 'list' ? 4096 : 1024"
    min-height="8rem"
    resize
    show-character-count
    @update:model-value="patch({ body: $event })"
  />

  <Input
    :model-value="data.footer"
    label="النص السفلي"
    maxlength="60"
    @update:model-value="patch({ footer: $event })"
  />
</template>
