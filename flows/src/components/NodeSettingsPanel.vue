<script setup>
import { computed } from 'vue';
import { NODE_TYPES } from '../domain/constants';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import TriggerSettings from './settings/TriggerSettings.vue';
import InteractiveSettings from './settings/InteractiveSettings.vue';
import InteractiveButtonSettings from './settings/InteractiveButtonSettings.vue';
import InteractiveListSettings from './settings/InteractiveListSettings.vue';
import MediaSettings from './settings/MediaSettings.vue';
import ConditionSettings from './settings/ConditionSettings.vue';
import LocationSettings from './settings/LocationSettings.vue';
import LocationRequestSettings from './settings/LocationRequestSettings.vue';
import ReactionSettings from './settings/ReactionSettings.vue';
import ContactSettings from './settings/ContactSettings.vue';
import CtaUrlSettings from './settings/CtaUrlSettings.vue';
import CarouselSettings from './settings/CarouselSettings.vue';
import StickerSettings from './settings/StickerSettings.vue';

const props = defineProps({ node: { type: Object, default: null } });
const emit = defineEmits(['update', 'close']);

const title = computed(
  () =>
    ({
      trigger: 'إعدادات نقطة البداية',
      text: 'إعدادات النص',
      image: 'إعدادات الصورة',
      video: 'إعدادات الفيديو',
      document: 'إعدادات المستند',
      audio: 'إعدادات الصوت',
      condition: 'إعدادات الشرط',
      location: 'إعدادات الموقع',
      location_request: 'إعدادات طلب الموقع',
      contact: 'إعدادات جهة الاتصال',
      sticker: 'إعدادات الملصق',
      reaction: 'إعدادات التفاعل',
      cta_url: 'إعدادات زر الرابط',
      carousel: 'إعدادات معرض الوسائط',
      interactive: 'إعدادات الرسالة التفاعلية',
      interactive_button: 'إعدادات زر الرد',
      interactive_list: 'إعدادات رسالة القائمة',
    })[props.node?.type] || ''
);

const data = computed(() => props.node?.data || {});

const patch = changes => emit('update', { ...data.value, ...changes });
</script>

<template>
  <div class="contents">
    <aside
      v-if="node"
      class="absolute bottom-3 right-3 top-3 z-30 flex w-80 flex-col overflow-hidden rounded-xl border border-n-weak bg-n-background/95 shadow-xl backdrop-blur"
    >
      <header
        class="flex items-center justify-between border-b border-n-weak px-5 py-4"
      >
        <div>
          <p class="text-[10px] uppercase tracking-wider text-n-slate-10">
            {{ $t('FLOW_BUILDER.SETTINGS.TITLE') }}
          </p>
          <h2 class="mt-1 text-sm font-medium text-n-slate-12">{{ title }}</h2>
        </div>
        <button
          class="flow-icon-btn"
          :aria-label="$t('FLOW_BUILDER.SETTINGS.CLOSE')"
          @click="$emit('close')"
        >
          <span class="i-lucide-x size-4" />
        </button>
      </header>

      <div class="flex-1 space-y-5 overflow-y-auto p-5">
        <template v-if="node.type === NODE_TYPES.TRIGGER">
          <TriggerSettings :data="data" @update="$emit('update', $event)" />
        </template>

        <template v-else-if="node.type === NODE_TYPES.TEXT">
          <TextArea
            :model-value="data.content"
            :label="$t('FLOW_BUILDER.SETTINGS.CONTENT')"
            :max-length="4096"
            min-height="10rem"
            resize
            show-character-count
            @update:model-value="patch({ content: $event })"
          />
        </template>

        <template v-else-if="node.type === NODE_TYPES.INTERACTIVE">
          <InteractiveSettings :data="data" @update="$emit('update', $event)" />
        </template>

        <template v-else-if="node.type === NODE_TYPES.INTERACTIVE_BUTTON">
          <InteractiveButtonSettings
            :data="data"
            @update="$emit('update', $event)"
          />
        </template>

        <template v-else-if="node.type === NODE_TYPES.INTERACTIVE_LIST">
          <InteractiveListSettings
            :data="data"
            @update="$emit('update', $event)"
          />
        </template>

        <template v-else-if="node.type === NODE_TYPES.CONDITION">
          <ConditionSettings :data="data" @update="$emit('update', $event)" />
        </template>

        <template v-else-if="node.type === NODE_TYPES.LOCATION">
          <LocationSettings :data="data" @update="$emit('update', $event)" />
        </template>
        <template v-else-if="node.type === NODE_TYPES.LOCATION_REQUEST">
          <LocationRequestSettings
            :data="data"
            @update="$emit('update', $event)"
          />
        </template>
        <template v-else-if="node.type === NODE_TYPES.CONTACT">
          <ContactSettings :data="data" @update="$emit('update', $event)" />
        </template>
        <template v-else-if="node.type === NODE_TYPES.REACTION">
          <ReactionSettings :data="data" @update="$emit('update', $event)" />
        </template>
        <template v-else-if="node.type === NODE_TYPES.CTA_URL">
          <CtaUrlSettings :data="data" @update="$emit('update', $event)" />
        </template>
        <template v-else-if="node.type === NODE_TYPES.CAROUSEL">
          <CarouselSettings :data="data" @update="$emit('update', $event)" />
        </template>
        <template v-else-if="node.type === NODE_TYPES.STICKER">
          <StickerSettings :data="data" @update="$emit('update', $event)" />
        </template>

        <template v-else>
          <MediaSettings
            :data="data"
            :node-type="node.type"
            @update="$emit('update', $event)"
          />
        </template>
      </div>
      <footer class="border-t border-n-weak p-4">
        <Button
          class="w-full"
          :label="$t('FLOW_BUILDER.SETTINGS.DONE')"
          color="blue"
          @click="$emit('close')"
        />
      </footer>
    </aside>
  </div>
</template>
