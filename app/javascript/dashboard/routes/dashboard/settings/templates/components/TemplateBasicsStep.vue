<script setup>
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Input from 'dashboard/components-next/input/Input.vue';

defineProps({
  categories: { type: Array, required: true },
  inboxOptions: { type: Array, required: true },
  languages: { type: Array, required: true },
  nameError: { type: String, default: '' },
  canContinue: { type: Boolean, required: true },
});
defineEmits(['continue']);
const state = defineModel('state', { type: Object, required: true });
const { t } = useI18n();
</script>

<template>
  <div class="grid w-full max-w-4xl gap-8 mx-auto pt-8">
    <section class="grid gap-4">
      <h3 class="text-base font-semibold text-n-slate-12">
        {{ t('WHATSAPP_TEMPLATE_BUILDER.CATEGORY_LABEL') }}
      </h3>
      <div class="grid grid-cols-1 gap-3 md:grid-cols-3">
        <button
          v-for="category in categories"
          :key="category.value"
          type="button"
          class="flex items-center gap-3 p-4 text-start border-2 border-solid rounded-xl shadow-sm transition-all bg-n-alpha-3"
          :class="
            state.category === category.value
              ? 'border-[#2f9683] shadow-md bg-n-brand/5'
              : 'border-[#cbd5e1] hover:border-[#94a3b8] hover:shadow-md'
          "
          @click="state.category = category.value"
        >
          <span
            class="grid rounded-lg size-11 shrink-0 place-items-center"
            :class="
              state.category === category.value
                ? 'bg-n-brand/10 text-n-brand'
                : 'bg-n-alpha-2 text-n-slate-11'
            "
          >
            <Icon :icon="category.icon" class="size-5" />
          </span>
          <span class="flex flex-col min-w-0 gap-1">
            <span class="text-sm font-semibold text-n-slate-12">
              {{ category.label }}
            </span>
            <span class="text-xs text-n-slate-10">
              {{ category.description }}
            </span>
          </span>
          <span
            class="grid ms-auto border-2 border-solid rounded-full size-5 shrink-0 place-items-center"
            :class="
              state.category === category.value
                ? 'border-n-brand bg-n-brand text-white'
                : 'border-n-strong'
            "
          >
            <Icon
              v-if="state.category === category.value"
              icon="i-lucide-check"
              class="size-3"
            />
          </span>
        </button>
      </div>
    </section>

    <section class="grid gap-4">
      <h3 class="text-base font-semibold text-n-slate-12">
        {{ t('WHATSAPP_TEMPLATE_BUILDER.BASIC_SETTINGS') }}
      </h3>
      <div
        class="grid gap-5 p-5 border shadow-sm md:grid-cols-3 rounded-xl border-n-strong bg-n-alpha-3"
      >
        <div class="flex flex-col gap-1">
          <label class="mb-0.5 text-heading-3 text-n-slate-12">
            {{ t('WHATSAPP_TEMPLATE_BUILDER.INBOX.LABEL') }}
          </label>
          <ComboBox
            v-model="state.inboxId"
            :options="inboxOptions"
            :placeholder="t('WHATSAPP_TEMPLATE_BUILDER.INBOX.PLACEHOLDER')"
          />
          <span v-if="!inboxOptions.length" class="text-xs text-n-ruby-9">
            {{ t('WHATSAPP_TEMPLATE_BUILDER.INBOX.EMPTY') }}
          </span>
        </div>
        <Input
          v-model="state.name"
          maxlength="512"
          :label="t('WHATSAPP_TEMPLATE_BUILDER.NAME.LABEL')"
          :placeholder="t('WHATSAPP_TEMPLATE_BUILDER.NAME.PLACEHOLDER')"
          :message="nameError || t('WHATSAPP_TEMPLATE_BUILDER.NAME.HELPER')"
          :message-type="nameError ? 'error' : 'info'"
          @input="
            state.name = state.name.toLowerCase().replace(/[^a-z0-9_]/g, '')
          "
        />
        <div class="flex flex-col gap-1">
          <label class="mb-0.5 text-heading-3 text-n-slate-12">
            {{ t('WHATSAPP_TEMPLATE_BUILDER.LANGUAGE_LABEL') }}
          </label>
          <ComboBox
            v-model="state.language"
            :options="languages"
            :placeholder="t('WHATSAPP_TEMPLATE_BUILDER.LANGUAGE_PLACEHOLDER')"
          />
        </div>
      </div>
    </section>
    <div class="flex justify-end">
      <Button
        :label="t('WHATSAPP_TEMPLATE_BUILDER.CONTINUE')"
        icon="i-lucide-arrow-right"
        trailing-icon
        :disabled="!canContinue"
        @click="$emit('continue')"
      />
    </div>
  </div>
</template>
