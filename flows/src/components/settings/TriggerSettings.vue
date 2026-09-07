<script setup>
import { computed, ref } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import RadioCard from 'dashboard/components-next/radioCard/RadioCard.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import { MATCH_TYPES, NO_MATCH_FREQUENCIES } from '../../domain/constants';

const props = defineProps({ data: { type: Object, required: true } });
const emit = defineEmits(['update']);
const keywordInput = ref('');
const noMatchDescription =
  'يلتقط أول كلمة يرسلها العميل عند عدم تطابق أي نقطة بداية أخرى في القناة.';
const frequencyLabel = 'تكرار الالتقاط للعميل';

const patch = changes => emit('update', { ...props.data, ...changes });
const matchOptions = MATCH_TYPES.map(({ id, label }) => ({ value: id, label }));
const frequencyOptions = NO_MATCH_FREQUENCIES.map(({ id, label }) => ({
  value: id,
  label,
}));
const keywords = computed(() => props.data.keywords || []);

const addKeyword = () => {
  const keyword = keywordInput.value.trim();
  if (!keyword || keywords.value.includes(keyword)) return;
  patch({ keywords: [...keywords.value, keyword] });
  keywordInput.value = '';
};

const removeKeyword = keyword =>
  patch({ keywords: keywords.value.filter(item => item !== keyword) });
</script>

<template>
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
          { id: 'exact_match', label: 'تطابق الكلمة' },
          { id: 'no_match', label: 'رسالة الترحيب' },
        ]"
        :id="`node-trigger-${option.id}`"
        :key="option.id"
        name="node-trigger-mode"
        :label="option.label"
        :description="option.label"
        :is-active="data.mode === option.id"
        @select="patch({ mode: option.id })"
      />
    </div>
  </fieldset>

  <template v-if="data.mode === 'no_match'">
    <p class="rounded-lg bg-n-alpha-2 p-3 text-xs leading-5 text-n-slate-11">
      {{ noMatchDescription }}
    </p>
    <label class="block space-y-2">
      <span class="flow-label">{{ frequencyLabel }}</span>
      <Select
        :model-value="data.noMatchFrequency || 'always'"
        :options="frequencyOptions"
        @update:model-value="patch({ noMatchFrequency: $event })"
      />
    </label>
  </template>

  <template v-else>
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
      <span class="flow-label">{{ $t('FLOW_BUILDER.SETTINGS.KEYWORDS') }}</span>
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
          v-for="keyword in keywords"
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
