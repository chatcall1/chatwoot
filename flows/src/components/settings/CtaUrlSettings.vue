<script setup>
import { computed } from 'vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import MediaSettings from './MediaSettings.vue';

const props = defineProps({ data: { type: Object, required: true } });
const emit = defineEmits(['update']);
const labels = {
  header: 'نوع الترويسة',
  headerText: 'نص الترويسة',
  body: 'نص الرسالة',
  button: 'نص الزر',
  url: 'رابط الزر',
  footer: 'النص السفلي',
};
const headerOptions = [
  { value: 'none', label: 'بدون ترويسة' },
  { value: 'text', label: 'نص' },
  { value: 'image', label: 'صورة' },
  { value: 'video', label: 'فيديو' },
  { value: 'document', label: 'مستند' },
];
const mediaData = computed(() => ({
  blobSignedId: props.data.headerBlobSignedId || '',
  filename: props.data.headerFilename || '',
  contentType: props.data.headerContentType || '',
  byteSize: props.data.headerByteSize || 0,
}));
const patch = changes => emit('update', { ...props.data, ...changes });
const selectHeader = headerType =>
  patch({
    headerType,
    headerBlobSignedId: '',
    headerFilename: '',
    headerContentType: '',
    headerByteSize: 0,
  });
const updateMedia = media =>
  patch({
    headerBlobSignedId: media.blobSignedId,
    headerFilename: media.filename,
    headerContentType: media.contentType,
    headerByteSize: media.byteSize,
  });
</script>

<template>
  <Select
    :model-value="data.headerType"
    :label="labels.header"
    :options="headerOptions"
    @update:model-value="selectHeader"
  />
  <Input
    v-if="data.headerType === 'text'"
    :model-value="data.headerText"
    :label="labels.headerText"
    maxlength="60"
    @update:model-value="patch({ headerText: $event })"
  />
  <MediaSettings
    v-else-if="['image', 'video', 'document'].includes(data.headerType)"
    :data="mediaData"
    :node-type="data.headerType"
    :show-caption="false"
    @update="updateMedia"
  />
  <TextArea
    :model-value="data.body"
    :label="labels.body"
    :max-length="1024"
    min-height="8rem"
    resize
    show-character-count
    @update:model-value="patch({ body: $event })"
  />
  <Input
    :model-value="data.buttonText"
    :label="labels.button"
    maxlength="20"
    @update:model-value="patch({ buttonText: $event })"
  />
  <Input
    :model-value="data.url"
    type="url"
    :label="labels.url"
    @update:model-value="patch({ url: $event })"
  />
  <Input
    :model-value="data.footer"
    :label="labels.footer"
    maxlength="60"
    @update:model-value="patch({ footer: $event })"
  />
</template>
