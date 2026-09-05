<script setup>
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Input from 'dashboard/components-next/input/Input.vue';

defineProps({
  catalogOptions: { type: Array, required: true },
  catalogFormats: { type: Array, required: true },
  productCarouselButtonTypes: { type: Array, required: true },
  productTemplateTypes: { type: Array, required: true },
  isLoadingCatalogs: { type: Boolean, required: true },
  hasFetchedCatalogs: { type: Boolean, required: true },
  variableIndexes: { type: Function, required: true },
});
defineEmits(['fetchCatalogs']);
const selectedCatalogId = defineModel('selectedCatalogId', {
  type: String,
  required: true,
});
const catalogFormat = defineModel('catalogFormat', {
  type: String,
  required: true,
});
const productTemplateType = defineModel('productTemplateType', {
  type: String,
  required: true,
});
const productCarouselButtonType = defineModel('productCarouselButtonType', {
  type: String,
  required: true,
});
const productCarouselUrl = defineModel('productCarouselUrl', {
  type: Object,
  required: true,
});
const { t } = useI18n();
</script>

<template>
  <section
    class="grid gap-3 p-4 border rounded-xl border-n-strong bg-n-alpha-1"
  >
    <div class="flex items-end gap-2">
      <ComboBox
        v-model="selectedCatalogId"
        class="flex-1"
        :options="catalogOptions"
        :label="t('WHATSAPP_TEMPLATE_BUILDER.CATALOG.SELECT_LABEL')"
        :placeholder="t('WHATSAPP_TEMPLATE_BUILDER.CATALOG.SELECT_PLACEHOLDER')"
        :disabled="isLoadingCatalogs"
      />
      <Button
        icon="i-lucide-refresh-cw"
        color="slate"
        variant="outline"
        :is-loading="isLoadingCatalogs"
        :aria-label="t('WHATSAPP_TEMPLATE_BUILDER.CATALOG.FETCH')"
        @click="$emit('fetchCatalogs')"
      />
    </div>
    <p
      v-if="hasFetchedCatalogs && !isLoadingCatalogs && !catalogOptions.length"
      class="text-xs text-n-slate-10"
    >
      {{ t('WHATSAPP_TEMPLATE_BUILDER.CATALOG.EMPTY') }}
    </p>
    <div class="grid grid-cols-1 gap-2 md:grid-cols-2">
      <button
        v-for="format in catalogFormats"
        :key="format.value"
        type="button"
        class="flex items-center gap-3 p-3 text-start border-2 border-solid rounded-xl transition-colors"
        :class="
          catalogFormat === format.value
            ? 'border-n-brand bg-n-brand/5'
            : 'border-n-slate-8 hover:border-n-slate-10'
        "
        @click="catalogFormat = format.value"
      >
        <span
          class="grid rounded-lg size-10 shrink-0 place-items-center bg-n-alpha-2 text-n-brand"
        >
          <Icon :icon="format.icon" class="size-5" />
        </span>
        <span class="flex flex-col gap-1">
          <span class="text-sm font-semibold text-n-slate-12">{{
            format.label
          }}</span>
          <span class="text-xs text-n-slate-10">{{ format.description }}</span>
        </span>
      </button>
    </div>
    <div
      v-if="catalogFormat === 'catalog_template'"
      class="flex items-start gap-3 p-3 border rounded-lg border-n-weak bg-n-alpha-1"
    >
      <Icon
        icon="i-lucide-shopping-bag"
        class="mt-0.5 size-4 shrink-0 text-n-brand"
      />
      <p class="text-xs leading-5 text-n-slate-11">
        {{ t('WHATSAPP_TEMPLATE_BUILDER.CATALOG.CATALOG_BUTTON_HELPER') }}
      </p>
    </div>
    <div
      v-if="catalogFormat === 'product_carousel'"
      class="grid gap-3 p-3 border rounded-lg border-n-weak bg-n-alpha-1"
    >
      <p class="text-xs leading-5 text-n-slate-11">
        {{ t('WHATSAPP_TEMPLATE_BUILDER.CATALOG.PRODUCT_CAROUSEL_HELPER') }}
      </p>
      <div class="grid grid-cols-2 gap-2">
        <button
          v-for="buttonType in productCarouselButtonTypes"
          :key="buttonType.value"
          type="button"
          class="p-3 text-sm text-start border-2 border-solid rounded-lg"
          :class="
            productCarouselButtonType === buttonType.value
              ? 'border-n-brand bg-n-brand/5 text-n-brand'
              : 'border-n-slate-8 text-n-slate-12 hover:border-n-slate-10'
          "
          @click="productCarouselButtonType = buttonType.value"
        >
          {{ buttonType.label }}
        </button>
      </div>
      <div
        v-if="productCarouselButtonType === 'URL'"
        class="grid gap-3 md:grid-cols-2"
      >
        <Input
          v-model="productCarouselUrl.text"
          :label="t('WHATSAPP_TEMPLATE_BUILDER.CATALOG.BUTTONS.URL_TEXT')"
          :placeholder="
            t('WHATSAPP_TEMPLATE_BUILDER.CATALOG.BUTTONS.URL_TEXT_PLACEHOLDER')
          "
        />
        <Input
          v-model="productCarouselUrl.url"
          :label="t('WHATSAPP_TEMPLATE_BUILDER.CATALOG.BUTTONS.URL_VALUE')"
          :placeholder="
            t('WHATSAPP_TEMPLATE_BUILDER.CATALOG.BUTTONS.URL_PLACEHOLDER')
          "
        />
        <Input
          v-if="variableIndexes(productCarouselUrl.url).length"
          v-model="productCarouselUrl.example"
          :label="t('WHATSAPP_TEMPLATE_BUILDER.CATALOG.BUTTONS.URL_EXAMPLE')"
        />
      </div>
    </div>
    <div
      v-if="catalogFormat === 'products'"
      class="grid grid-cols-1 gap-2 md:grid-cols-2"
    >
      <button
        v-for="type in productTemplateTypes"
        :key="type.value"
        type="button"
        class="flex items-center gap-3 p-3 text-start border-2 border-solid rounded-xl"
        :class="
          productTemplateType === type.value
            ? 'border-n-brand bg-n-brand/5'
            : 'border-n-slate-8 hover:border-n-slate-10'
        "
        @click="productTemplateType = type.value"
      >
        <Icon :icon="type.icon" class="size-5 text-n-brand" />
        <span>
          <span class="block text-sm font-semibold text-n-slate-12">
            {{ type.label }}
          </span>
          <span class="block mt-1 text-xs text-n-slate-10">{{
            type.description
          }}</span>
        </span>
      </button>
    </div>
  </section>
</template>
