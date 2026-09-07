<script setup>
import { computed } from 'vue';
import { Handle, Position } from '@vue-flow/core';
import NodeActions from './NodeActions.vue';

const props = defineProps({
  data: { type: Object, required: true },
  selected: { type: Boolean, default: false },
  nodeType: { type: String, required: true },
});
defineEmits(['duplicate', 'delete']);

const config = computed(
  () =>
    ({
      location: ['موقع', 'i-lucide-map-pin'],
      location_request: ['طلب موقع العميل', 'i-lucide-locate-fixed'],
      contact: ['جهة اتصال', 'i-lucide-contact'],
      sticker: ['ملصق', 'i-lucide-sticker'],
      reaction: ['تفاعل مع رسالة التشغيل', 'i-lucide-smile-plus'],
      cta_url: ['زر رابط', 'i-lucide-external-link'],
      carousel: ['معرض وسائط', 'i-lucide-gallery-horizontal'],
    })[props.nodeType]
);

const preview = computed(() => {
  if (props.nodeType === 'location')
    return props.data.name || props.data.address;
  if (props.nodeType === 'contact') return props.data.name?.formatted_name;
  if (props.nodeType === 'sticker') return props.data.filename;
  if (props.nodeType === 'reaction') return props.data.emoji;
  return props.data.body;
});
const carouselReplies = computed(() =>
  props.nodeType === 'carousel' && props.data.buttonType === 'quick_reply'
    ? props.data.cards.flatMap((card, cardIndex) =>
        card.replies.map(reply => ({ ...reply, cardIndex }))
      )
    : []
);
const emptyLabel = 'افتح إعدادات النود لإكمالها';
const platformLabel = 'WhatsApp';
const replySeparator = '—';
</script>

<template>
  <article
    class="relative w-64 rounded-2xl border bg-n-background shadow-xl transition"
    :class="
      selected ? 'border-n-brand ring-2 ring-n-brand/20' : 'border-n-strong'
    "
  >
    <NodeActions
      :selected="selected"
      @duplicate="$emit('duplicate')"
      @delete="$emit('delete')"
    />
    <Handle
      type="target"
      :position="Position.Top"
      class="!size-3 !border-2 !border-black !bg-n-slate-8"
    />
    <header class="flex items-center gap-3 border-b border-n-weak px-4 py-3">
      <span
        class="flex size-9 items-center justify-center rounded-xl bg-n-teal-3 text-n-teal-11"
      >
        <span class="size-4" :class="config[1]" />
      </span>
      <div class="min-w-0">
        <p class="text-[10px] font-semibold uppercase text-n-teal-11">
          {{ platformLabel }}
        </p>
        <h3 class="truncate text-sm font-medium text-n-slate-12">
          {{ config[0] }}
        </h3>
      </div>
    </header>
    <p
      class="line-clamp-2 min-h-14 px-4 py-3 text-xs leading-5 text-n-slate-11"
    >
      {{ preview || emptyLabel }}
    </p>
    <div v-if="carouselReplies.length" class="border-t border-n-weak px-3 py-2">
      <div
        v-for="reply in carouselReplies"
        :key="reply.id"
        class="relative mb-1 rounded-lg bg-n-alpha-2 px-2 py-1 text-xs text-n-slate-11"
      >
        {{ reply.cardIndex + 1 }} {{ replySeparator }}
        {{ reply.title || emptyLabel }}
        <Handle
          :id="`reply:${reply.id}`"
          type="source"
          :position="Position.Right"
          class="!size-3 !border-2 !border-black !bg-n-brand"
        />
      </div>
    </div>
    <Handle
      v-else
      type="source"
      :position="Position.Bottom"
      class="!size-3 !border-2 !border-black !bg-n-brand"
    />
  </article>
</template>
