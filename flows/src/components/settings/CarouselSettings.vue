<script setup>
import Input from 'dashboard/components-next/input/Input.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import MediaSettings from './MediaSettings.vue';
import { generateId } from '../../utils/id';

const props = defineProps({ data: { type: Object, required: true } });
const emit = defineEmits(['update']);
const labels = {
  body: 'النص الرئيسي',
  card: 'بطاقة',
  mediaType: 'نوع الوسائط',
  cardBody: 'نص البطاقة',
  button: 'نص الزر',
  url: 'رابط الزر',
  add: 'إضافة بطاقة',
  remove: 'حذف البطاقة',
  buttonType: 'نوع أزرار البطاقات',
  replies: 'الردود السريعة',
  reply: 'نص الرد',
  addReply: 'إضافة رد',
};
const mediaOptions = [
  { value: 'image', label: 'صورة' },
  { value: 'video', label: 'فيديو' },
];
const buttonOptions = [
  { value: 'url', label: 'زر رابط' },
  { value: 'quick_reply', label: 'ردود سريعة' },
];
const patch = changes => emit('update', { ...props.data, ...changes });
const updateCard = (index, changes) =>
  patch({
    cards: props.data.cards.map((card, cardIndex) =>
      cardIndex === index ? { ...card, ...changes } : card
    ),
  });
const addCard = () => {
  if (props.data.cards.length >= 10) return;
  patch({
    cards: [
      ...props.data.cards,
      {
        id: generateId(),
        headerType: 'image',
        blobSignedId: '',
        filename: '',
        contentType: '',
        byteSize: 0,
        body: '',
        buttonText: '',
        url: '',
        replies: [{ id: generateId(), title: '' }],
      },
    ],
  });
};
const removeCard = index => {
  if (props.data.cards.length <= 2) return;
  patch({
    cards: props.data.cards.filter((_, cardIndex) => cardIndex !== index),
  });
};
const selectMedia = (index, headerType) =>
  updateCard(index, {
    headerType,
    blobSignedId: '',
    filename: '',
    contentType: '',
    byteSize: 0,
  });
const addReply = () => {
  if (props.data.cards.some(card => card.replies.length >= 3)) return;
  patch({
    cards: props.data.cards.map(card => ({
      ...card,
      replies: [...card.replies, { id: generateId(), title: '' }],
    })),
  });
};
const removeReply = replyIndex => {
  if (props.data.cards.some(card => card.replies.length <= 1)) return;
  patch({
    cards: props.data.cards.map(card => ({
      ...card,
      replies: card.replies.filter((_, index) => index !== replyIndex),
    })),
  });
};
const updateReply = (cardIndex, replyIndex, title) =>
  updateCard(cardIndex, {
    replies: props.data.cards[cardIndex].replies.map((reply, index) =>
      index === replyIndex ? { ...reply, title } : reply
    ),
  });
</script>

<template>
  <TextArea
    :model-value="data.body"
    :label="labels.body"
    :max-length="1024"
    min-height="7rem"
    resize
    show-character-count
    @update:model-value="patch({ body: $event })"
  />
  <Select
    :model-value="data.buttonType"
    :label="labels.buttonType"
    :options="buttonOptions"
    @update:model-value="patch({ buttonType: $event })"
  />
  <section
    v-for="(card, index) in data.cards"
    :key="card.id"
    class="space-y-3 rounded-xl border border-n-strong p-3"
  >
    <div class="flex items-center justify-between">
      <span class="text-sm font-medium text-n-slate-12">
        {{ labels.card }} {{ index + 1 }}
      </span>
      <button
        class="flow-icon-btn"
        type="button"
        :disabled="data.cards.length <= 2"
        :title="labels.remove"
        @click="removeCard(index)"
      >
        <span class="i-lucide-trash-2 size-4" />
      </button>
    </div>
    <Select
      :model-value="card.headerType"
      :label="labels.mediaType"
      :options="mediaOptions"
      @update:model-value="selectMedia(index, $event)"
    />
    <MediaSettings
      :data="card"
      :node-type="card.headerType"
      :show-caption="false"
      @update="updateCard(index, $event)"
    />
    <TextArea
      :model-value="card.body"
      :label="labels.cardBody"
      :max-length="160"
      min-height="5rem"
      resize
      show-character-count
      @update:model-value="updateCard(index, { body: $event })"
    />
    <Input
      v-if="data.buttonType === 'url'"
      :model-value="card.buttonText"
      :label="labels.button"
      maxlength="20"
      @update:model-value="updateCard(index, { buttonText: $event })"
    />
    <Input
      v-if="data.buttonType === 'url'"
      :model-value="card.url"
      type="url"
      :label="labels.url"
      @update:model-value="updateCard(index, { url: $event })"
    />
    <div v-else class="space-y-2">
      <div class="flex items-center justify-between">
        <span class="flow-label">{{ labels.replies }}</span>
        <button
          class="flow-icon-btn"
          type="button"
          :disabled="data.cards.some(item => item.replies.length >= 3)"
          :title="labels.addReply"
          @click="addReply"
        >
          <span class="i-lucide-plus size-4" />
        </button>
      </div>
      <div
        v-for="(reply, replyIndex) in card.replies"
        :key="reply.id"
        class="flex gap-2"
      >
        <Input
          class="flex-1"
          :model-value="reply.title"
          :label="labels.reply"
          maxlength="20"
          @update:model-value="updateReply(index, replyIndex, $event)"
        />
        <button
          class="flow-icon-btn mt-6"
          type="button"
          :disabled="data.cards.some(item => item.replies.length <= 1)"
          :title="labels.remove"
          @click="removeReply(replyIndex)"
        >
          <span class="i-lucide-trash-2 size-4" />
        </button>
      </div>
    </div>
  </section>
  <button
    class="flow-btn w-full"
    type="button"
    :disabled="data.cards.length >= 10"
    @click="addCard"
  >
    <span class="i-lucide-plus size-4" />{{ labels.add }}
  </button>
</template>
