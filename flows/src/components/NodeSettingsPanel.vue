<script setup>
import { computed, ref, watch } from 'vue';
import { MATCH_TYPES, NODE_TYPES } from '../domain/constants';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import RadioCard from 'dashboard/components-next/radioCard/RadioCard.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import { generateId } from '../utils/id';

const props = defineProps({ node: { type: Object, default: null } });
const emit = defineEmits(['update', 'close']);
const keywordInput = ref('');
const MEDIA_URL_PLACEHOLDER = 'https://example.com/file';
const DOCUMENT_NAME_PLACEHOLDER = 'document.pdf';

const title = computed(
  () =>
    ({
      trigger: 'إعدادات نقطة البداية',
      text: 'إعدادات النص',
      image: 'إعدادات الصورة',
      video: 'إعدادات الفيديو',
      document: 'إعدادات المستند',
      interactive: 'إعدادات الرسالة التفاعلية',
      interactive_button: 'إعدادات زر الرد',
      interactive_list: 'إعدادات رسالة القائمة',
    })[props.node?.type] || ''
);

const data = computed(() => props.node?.data || {});

watch(
  () => props.node?.id,
  () => {
    keywordInput.value = '';
  }
);

const patch = changes => emit('update', { ...data.value, ...changes });

const addKeyword = () => {
  const keyword = keywordInput.value.trim();
  if (!keyword || data.value.keywords?.includes(keyword)) return;
  patch({ keywords: [...(data.value.keywords || []), keyword] });
  keywordInput.value = '';
};

const removeKeyword = keyword =>
  patch({ keywords: data.value.keywords.filter(item => item !== keyword) });

const matchOptions = MATCH_TYPES.map(type => ({
  value: type.id,
  label: type.label,
}));
const headerOptions = [
  { value: 'none', label: 'بدون هيدر' },
  { value: 'text', label: 'نص' },
  { value: 'image', label: 'صورة' },
  { value: 'video', label: 'فيديو' },
  { value: 'document', label: 'مستند' },
];

const updateItem = (key, id, value) =>
  patch({
    [key]: data.value[key].map(item =>
      item.id === id ? { ...item, title: value } : item
    ),
  });

const interactiveLabels = {
  headerType: 'نوع الهيدر',
  rows: 'صفوف القائمة',
};

const addItem = key => {
  const limit = key === 'buttons' ? 3 : 10;
  if (data.value[key].length >= limit) return;
  patch({
    [key]: [
      ...data.value[key],
      { id: generateId(), title: `الخيار ${data.value[key].length + 1}` },
    ],
  });
};

const removeItem = (key, id) => {
  if (data.value[key].length <= 1) return;
  patch({ [key]: data.value[key].filter(item => item.id !== id) });
};
</script>

<template>
  <div class="contents">
    <aside
      v-if="node"
      class="flex h-full w-80 shrink-0 flex-col border-r border-n-weak bg-n-background"
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
          <Input
            :model-value="data.label"
            :label="$t('FLOW_BUILDER.SETTINGS.TRIGGER_NAME')"
            @update:model-value="patch({ label: $event })"
          />

          <fieldset>
            <legend class="flow-label">
              {{ $t('FLOW_BUILDER.SETTINGS.TRIGGER_TYPE') }}
            </legend>
            <div class="space-y-2">
              <RadioCard
                v-for="option in [
                  { id: 'keywords', label: 'كلمات مفتاحية' },
                  { id: 'no_match', label: 'No Match' },
                ]"
                :id="`node-${node.id}-${option.id}`"
                :key="option.id"
                name="node-trigger-mode"
                :label="option.label"
                :description="option.label"
                :is-active="data.mode === option.id"
                @select="patch({ mode: option.id })"
              />
            </div>
          </fieldset>

          <template v-if="data.mode === 'keywords'">
            <label class="block space-y-2">
              <span class="flow-label">{{
                $t('FLOW_BUILDER.SETTINGS.MATCH_TYPE')
              }}</span>
              <Select
                :model-value="data.matchType"
                :options="matchOptions"
                @update:model-value="patch({ matchType: $event })"
              />
            </label>

            <div>
              <span class="flow-label">{{
                $t('FLOW_BUILDER.SETTINGS.KEYWORDS')
              }}</span>
              <form class="flex gap-2" @submit.prevent="addKeyword">
                <Input
                  v-model="keywordInput"
                  :placeholder="$t('FLOW_BUILDER.SETTINGS.KEYWORD_PLACEHOLDER')"
                  class="flex-1"
                />
                <Button
                  type="submit"
                  icon="i-lucide-plus"
                  color="slate"
                  :aria-label="$t('FLOW_BUILDER.SETTINGS.ADD_KEYWORD')"
                />
              </form>
              <div class="mt-3 flex flex-wrap gap-2">
                <button
                  v-for="keyword in data.keywords"
                  :key="keyword"
                  type="button"
                  class="inline-flex items-center gap-1 rounded-full bg-n-alpha-2 px-2.5 py-1 text-xs text-n-slate-11"
                  @click="removeKeyword(keyword)"
                >
                  {{ keyword }}
                  <span class="i-lucide-x size-3" />
                </button>
              </div>
            </div>
          </template>
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
          <div class="space-y-2">
            <span class="flow-label">{{ interactiveLabels.headerType }}</span>
            <Select
              :model-value="data.headerType"
              :options="headerOptions"
              @update:model-value="patch({ headerType: $event })"
            />
          </div>

          <Input
            v-if="data.headerType === 'text'"
            :model-value="data.headerText"
            label="نص الهيدر"
            maxlength="60"
            @update:model-value="patch({ headerText: $event })"
          />
          <Input
            v-else-if="['image', 'video', 'document'].includes(data.headerType)"
            :model-value="data.headerUrl"
            type="url"
            label="رابط ملف الهيدر"
            :placeholder="MEDIA_URL_PLACEHOLDER"
            custom-input-class="direction-ltr text-left"
            @update:model-value="patch({ headerUrl: $event })"
          />

          <TextArea
            :model-value="data.body"
            label="نص الرسالة"
            :max-length="1024"
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

        <template v-else-if="node.type === NODE_TYPES.INTERACTIVE_BUTTON">
          <Input
            :model-value="data.title"
            label="عنوان الزر"
            maxlength="20"
            @update:model-value="patch({ title: $event })"
          />
        </template>

        <template v-else-if="node.type === NODE_TYPES.INTERACTIVE_LIST">
          <TextArea
            :model-value="data.body"
            label="نص القائمة"
            :max-length="1024"
            min-height="7rem"
            resize
            show-character-count
            @update:model-value="patch({ body: $event })"
          />
          <Input
            :model-value="data.buttonText"
            label="نص زر فتح القائمة"
            maxlength="20"
            @update:model-value="patch({ buttonText: $event })"
          />
          <div class="space-y-2">
            <span class="flow-label">{{ interactiveLabels.rows }}</span>
            <div
              v-for="item in data.rows"
              :key="item.id"
              class="flex items-center gap-2"
            >
              <Input
                :model-value="item.title"
                maxlength="24"
                class="flex-1"
                @update:model-value="updateItem('rows', item.id, $event)"
              />
              <Button
                icon="i-lucide-trash-2"
                color="ruby"
                variant="ghost"
                size="sm"
                @click="removeItem('rows', item.id)"
              />
            </div>
            <Button
              label="إضافة صف"
              icon="i-lucide-plus"
              color="slate"
              variant="faded"
              size="sm"
              :disabled="data.rows.length >= 10"
              @click="addItem('rows')"
            />
          </div>
        </template>

        <template v-else>
          <Input
            :model-value="data.url"
            type="url"
            :label="$t('FLOW_BUILDER.SETTINGS.MEDIA_URL')"
            :placeholder="MEDIA_URL_PLACEHOLDER"
            custom-input-class="direction-ltr text-left"
            @update:model-value="patch({ url: $event })"
          />

          <Input
            v-if="node.type === NODE_TYPES.DOCUMENT"
            :model-value="data.filename"
            :label="$t('FLOW_BUILDER.SETTINGS.FILE_NAME')"
            :placeholder="DOCUMENT_NAME_PLACEHOLDER"
            @update:model-value="patch({ filename: $event })"
          />

          <TextArea
            :model-value="data.caption"
            :label="$t('FLOW_BUILDER.SETTINGS.CAPTION')"
            :max-length="1024"
            min-height="7rem"
            resize
            @update:model-value="patch({ caption: $event })"
          />
        </template>
      </div>
    </aside>
  </div>
</template>
