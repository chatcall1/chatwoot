<script setup>
/**
 * This component handles parsing and sending WhatsApp message templates.
 * It works as follows:
 * 1. Displays the template text with variable placeholders.
 * 2. Generates input fields for each variable in the template.
 * 3. Validates that all variables are filled before sending.
 * 4. Replaces placeholders with user-provided values.
 * 5. Emits events to send the processed message or reset the template.
 */
import { ref, computed, onMounted, watch } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { requiredIf } from '@vuelidate/validators';
import { useI18n } from 'vue-i18n';

import { isWhatsAppComplete } from '@chatwoot/utils';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import {
  buildTemplateParameters,
  allKeysRequired,
  DEFAULT_LANGUAGE,
  DEFAULT_CATEGORY,
  COMPONENT_TYPES,
  MEDIA_FORMATS,
  findComponentByType,
  renderTemplatePreview,
} from 'dashboard/helper/templateHelper';

const props = defineProps({
  template: {
    type: Object,
    default: () => ({}),
    validator: value => {
      if (!value || typeof value !== 'object') return false;
      if (!value.components || !Array.isArray(value.components)) return false;
      return true;
    },
  },
  sendRenderedContent: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['sendMessage', 'resetTemplate', 'back']);

const { t } = useI18n();

const processedParams = ref({});

const languageLabel = computed(() => {
  return `${t('WHATSAPP_TEMPLATES.PARSER.LANGUAGE')}: ${props.template.language || DEFAULT_LANGUAGE}`;
});

const categoryLabel = computed(() => {
  return `${t('WHATSAPP_TEMPLATES.PARSER.CATEGORY')}: ${props.template.category || DEFAULT_CATEGORY}`;
});

const headerComponent = computed(() => {
  return findComponentByType(props.template, COMPONENT_TYPES.HEADER);
});

const bodyComponent = computed(() => {
  return findComponentByType(props.template, COMPONENT_TYPES.BODY);
});

const bodyText = computed(() => {
  return bodyComponent.value?.text || '';
});

const headerText = computed(() => {
  return headerComponent.value?.format === 'TEXT'
    ? headerComponent.value?.text || ''
    : '';
});

const hasMediaHeader = computed(() =>
  MEDIA_FORMATS.includes(headerComponent.value?.format)
);

const formatType = computed(() => {
  const format = headerComponent.value?.format;
  return format ? format.charAt(0) + format.slice(1).toLowerCase() : '';
});

const isDocumentTemplate = computed(() => {
  return headerComponent.value?.format?.toLowerCase() === 'document';
});

const hasBodyVariables = computed(() => {
  return bodyText.value?.match(/{{([^}]+)}}/g) !== null;
});

const hasTextHeaderVariables = computed(() => {
  return headerText.value?.match(/{{([^}]+)}}/g) !== null;
});

const hasVariables = computed(
  () => hasBodyVariables.value || hasTextHeaderVariables.value
);
const buttonsComponent = computed(() =>
  findComponentByType(props.template, COMPONENT_TYPES.BUTTONS)
);
const commerceButtonType = computed(
  () =>
    buttonsComponent.value?.buttons?.find(button =>
      ['CATALOG', 'SPM', 'MPM'].includes(button.type)
    )?.type
);
const productCarouselComponent = computed(() =>
  props.template.components?.find(component => {
    if (component.type !== 'CAROUSEL') return false;
    return component.cards?.[0]?.components?.some(
      item => item.type === 'HEADER' && item.format === 'PRODUCT'
    );
  })
);
const hasCommerceParameters = computed(
  () => !!commerceButtonType.value || !!productCarouselComponent.value
);
const productCarouselHasDynamicUrl = computed(() =>
  productCarouselComponent.value?.cards?.[0]?.components
    ?.find(component => component.type === 'BUTTONS')
    ?.buttons?.some(
      button => button.type === 'URL' && button.url?.includes('{{')
    )
);

const renderedHeader = computed(() => {
  return renderTemplatePreview(
    headerText.value,
    processedParams.value.header || {}
  );
});

const renderedTemplate = computed(() => {
  return renderTemplatePreview(
    bodyText.value,
    processedParams.value.body || {}
  );
});

const v$ = useVuelidate(
  {
    processedParams: {
      requiredIfKeysPresent: requiredIf(hasVariables),
      allKeysRequired,
    },
  },
  { processedParams }
);

const initializeTemplateParameters = () => {
  processedParams.value = buildTemplateParameters(
    props.template,
    hasMediaHeader.value
  );
  if (commerceButtonType.value === 'CATALOG') {
    processedParams.value.catalog = { thumbnail_product_retailer_id: '' };
  } else if (commerceButtonType.value === 'SPM') {
    processedParams.value.product = { product_retailer_id: '' };
  } else if (commerceButtonType.value === 'MPM') {
    processedParams.value.catalog = {
      thumbnail_product_retailer_id: '',
      sections: [{ title: '', product_retailer_ids: [''] }],
    };
  } else if (productCarouselComponent.value) {
    processedParams.value.carousel = {
      cards: productCarouselComponent.value.cards.map(() => ({
        product_retailer_id: '',
        url_parameter: '',
      })),
    };
  }
};

const hasCompleteCommerceParameters = computed(() => {
  if (commerceButtonType.value === 'SPM') {
    return !!processedParams.value.product?.product_retailer_id?.trim();
  }
  if (commerceButtonType.value === 'MPM') {
    const catalog = processedParams.value.catalog;
    const sections = catalog?.sections || [];
    const productCount = sections.reduce(
      (count, section) =>
        count + section.product_retailer_ids.filter(id => id.trim()).length,
      0
    );
    return (
      !!catalog?.thumbnail_product_retailer_id?.trim() &&
      sections.length >= 1 &&
      sections.length <= 10 &&
      productCount >= 1 &&
      productCount <= 30 &&
      sections.every(
        section =>
          !!section.title.trim() &&
          section.title.length <= 24 &&
          section.product_retailer_ids.some(id => id.trim())
      )
    );
  }
  if (productCarouselComponent.value) {
    const cards = processedParams.value.carousel?.cards || [];
    return (
      cards.length >= 2 &&
      cards.length <= 10 &&
      cards.every(
        card =>
          !!card.product_retailer_id.trim() &&
          (!productCarouselHasDynamicUrl.value || !!card.url_parameter.trim())
      )
    );
  }
  return true;
});

// Completeness validation is shared with the mobile app via @chatwoot/utils.
const isFormInvalid = computed(
  () =>
    !isWhatsAppComplete(props.template, processedParams.value) ||
    !hasCompleteCommerceParameters.value
);

const addProductSection = () => {
  if (processedParams.value.catalog.sections.length >= 10) return;
  processedParams.value.catalog.sections.push({
    title: '',
    product_retailer_ids: [''],
  });
};
const removeProductSection = index => {
  if (processedParams.value.catalog.sections.length === 1) return;
  processedParams.value.catalog.sections.splice(index, 1);
};
const addSectionProduct = section => {
  const count = processedParams.value.catalog.sections.reduce(
    (total, item) => total + item.product_retailer_ids.length,
    0
  );
  if (count < 30) section.product_retailer_ids.push('');
};
const removeSectionProduct = (section, index) => {
  if (section.product_retailer_ids.length === 1) return;
  section.product_retailer_ids.splice(index, 1);
};
const addProductCard = () => {
  const cards = processedParams.value.carousel.cards;
  if (cards.length >= 10) return;
  cards.push({ product_retailer_id: '', url_parameter: '' });
};
const removeProductCard = index => {
  const cards = processedParams.value.carousel.cards;
  if (cards.length <= 2) return;
  cards.splice(index, 1);
};

const updateMediaUrl = value => {
  processedParams.value.header ??= {};
  processedParams.value.header.media_url = value;
};

const updateMediaName = value => {
  processedParams.value.header ??= {};
  processedParams.value.header.media_name = value;
};

const sendMessage = () => {
  v$.value.$touch();
  if (isFormInvalid.value) return;

  const { name, category, language, namespace } = props.template;

  const payload = {
    message: props.sendRenderedContent
      ? renderedTemplate.value
      : bodyText.value,
    pendingMessageContent: renderedTemplate.value,
    templateParams: {
      name,
      category,
      language,
      namespace,
      content_mode: props.sendRenderedContent ? 'rendered' : 'raw_template',
      processed_params: processedParams.value,
    },
  };
  emit('sendMessage', payload);
};

const resetTemplate = () => {
  emit('resetTemplate');
};

const goBack = () => {
  emit('back');
};

onMounted(initializeTemplateParameters);

watch(
  () => props.template,
  () => {
    initializeTemplateParameters();
    v$.value.$reset();
  },
  { deep: true }
);

defineExpose({
  processedParams,
  hasVariables,
  hasMediaHeader,
  isDocumentTemplate,
  headerComponent,
  renderedHeader,
  renderedTemplate,
  isFormInvalid,
  v$,
  updateMediaUrl,
  updateMediaName,
  sendMessage,
  resetTemplate,
  goBack,
});
</script>

<template>
  <div>
    <div class="flex flex-col gap-4 p-4 mb-4 rounded-lg bg-n-alpha-black2">
      <div class="flex justify-between items-center">
        <h3 class="text-sm font-medium text-n-slate-12">
          {{ template.name }}
        </h3>
        <span class="text-xs text-n-slate-11">
          {{ languageLabel }}
        </span>
      </div>

      <div class="flex flex-col gap-2">
        <div class="rounded-md">
          <div
            v-if="renderedHeader"
            class="mb-2 text-sm font-medium whitespace-pre-wrap text-n-slate-12"
          >
            {{ renderedHeader }}
          </div>
          <div class="text-sm whitespace-pre-wrap text-n-slate-12">
            {{ renderedTemplate }}
          </div>
        </div>
      </div>

      <div class="text-xs text-n-slate-11">
        {{ categoryLabel }}
      </div>
    </div>

    <div v-if="hasVariables || hasMediaHeader || hasCommerceParameters">
      <div v-if="hasMediaHeader" class="mb-4">
        <p class="mb-2.5 text-sm font-semibold">
          {{
            $t('WHATSAPP_TEMPLATES.PARSER.MEDIA_HEADER_LABEL', {
              type: formatType,
            }) || `${formatType} Header`
          }}
        </p>
        <div class="flex items-center mb-2.5">
          <Input
            :model-value="processedParams.header?.media_url || ''"
            type="url"
            class="flex-1"
            :placeholder="
              t('WHATSAPP_TEMPLATES.PARSER.MEDIA_URL_LABEL', {
                type: formatType,
              })
            "
            @update:model-value="updateMediaUrl"
          />
        </div>
        <div v-if="isDocumentTemplate" class="flex items-center mb-2.5">
          <Input
            :model-value="processedParams.header?.media_name || ''"
            type="text"
            class="flex-1"
            :placeholder="
              t('WHATSAPP_TEMPLATES.PARSER.DOCUMENT_NAME_PLACEHOLDER')
            "
            @update:model-value="updateMediaName"
          />
        </div>
      </div>

      <!-- Text Header Variables Section -->
      <div v-if="hasTextHeaderVariables && processedParams.header">
        <p class="mb-2.5 text-sm font-semibold">
          {{ $t('WHATSAPP_TEMPLATES.PARSER.HEADER_VARIABLES_LABEL') }}
        </p>
        <div
          v-for="(variable, key) in processedParams.header"
          :key="`header-${key}`"
          class="flex items-center mb-2.5"
        >
          <Input
            v-model="processedParams.header[key]"
            type="text"
            class="flex-1"
            :placeholder="
              t('WHATSAPP_TEMPLATES.PARSER.VARIABLE_PLACEHOLDER', {
                variable: key,
              })
            "
          />
        </div>
      </div>

      <!-- Body Variables Section -->
      <div v-if="processedParams.body">
        <p class="mb-2.5 text-sm font-semibold">
          {{ $t('WHATSAPP_TEMPLATES.PARSER.VARIABLES_LABEL') }}
        </p>
        <div
          v-for="(variable, key) in processedParams.body"
          :key="`body-${key}`"
          class="flex items-center mb-2.5"
        >
          <Input
            v-model="processedParams.body[key]"
            type="text"
            class="flex-1"
            :placeholder="
              t('WHATSAPP_TEMPLATES.PARSER.VARIABLE_PLACEHOLDER', {
                variable: key,
              })
            "
          />
        </div>
      </div>

      <!-- Button Variables Section -->
      <div v-if="processedParams.buttons">
        <p class="mb-2.5 text-sm font-semibold">
          {{ t('WHATSAPP_TEMPLATES.PARSER.BUTTON_PARAMETERS') }}
        </p>
        <div
          v-for="(button, index) in processedParams.buttons"
          :key="`button-${index}`"
          class="flex items-center mb-2.5"
        >
          <Input
            v-model="processedParams.buttons[index].parameter"
            type="text"
            class="flex-1"
            :placeholder="t('WHATSAPP_TEMPLATES.PARSER.BUTTON_PARAMETER')"
          />
        </div>
      </div>
      <div v-if="commerceButtonType === 'CATALOG'" class="mb-4">
        <p class="mb-2.5 text-sm font-semibold">
          {{ t('WHATSAPP_TEMPLATES.PARSER.CATALOG_THUMBNAIL') }}
        </p>
        <Input
          v-model="processedParams.catalog.thumbnail_product_retailer_id"
          type="text"
          :placeholder="t('WHATSAPP_TEMPLATES.PARSER.OPTIONAL_PRODUCT_ID')"
        />
      </div>
      <div v-if="commerceButtonType === 'SPM'" class="mb-4">
        <p class="mb-2.5 text-sm font-semibold">
          {{ t('WHATSAPP_TEMPLATES.PARSER.PRODUCT_ID') }}
        </p>
        <Input
          v-model="processedParams.product.product_retailer_id"
          type="text"
          :placeholder="t('WHATSAPP_TEMPLATES.PARSER.PRODUCT_ID_PLACEHOLDER')"
        />
      </div>
      <div v-if="commerceButtonType === 'MPM'" class="grid gap-3 mb-4">
        <p class="text-sm font-semibold">
          {{ t('WHATSAPP_TEMPLATES.PARSER.PRODUCTS') }}
        </p>
        <Input
          v-model="processedParams.catalog.thumbnail_product_retailer_id"
          type="text"
          :placeholder="t('WHATSAPP_TEMPLATES.PARSER.THUMBNAIL_PRODUCT_ID')"
        />
        <div
          v-for="(section, sectionIndex) in processedParams.catalog.sections"
          :key="`section-${sectionIndex}`"
          class="grid gap-2 p-3 border rounded-lg border-n-strong"
        >
          <div class="flex items-center gap-2">
            <Input
              v-model="section.title"
              type="text"
              maxlength="24"
              class="flex-1"
              :placeholder="t('WHATSAPP_TEMPLATES.PARSER.SECTION_TITLE')"
            />
            <Button
              icon="i-lucide-trash-2"
              color="slate"
              variant="ghost"
              size="sm"
              :disabled="processedParams.catalog.sections.length === 1"
              :aria-label="t('WHATSAPP_TEMPLATES.PARSER.REMOVE_SECTION')"
              @click="removeProductSection(sectionIndex)"
            />
          </div>
          <div
            v-for="(productId, productIndex) in section.product_retailer_ids"
            :key="`section-${sectionIndex}-product-${productIndex}`"
            class="flex items-center gap-2"
          >
            <Input
              v-model="section.product_retailer_ids[productIndex]"
              type="text"
              class="flex-1"
              :placeholder="
                t('WHATSAPP_TEMPLATES.PARSER.PRODUCT_ID_PLACEHOLDER')
              "
            />
            <Button
              icon="i-lucide-x"
              color="slate"
              variant="ghost"
              size="sm"
              :disabled="section.product_retailer_ids.length === 1"
              :aria-label="t('WHATSAPP_TEMPLATES.PARSER.REMOVE_PRODUCT')"
              @click="removeSectionProduct(section, productIndex)"
            />
          </div>
          <Button
            :label="t('WHATSAPP_TEMPLATES.PARSER.ADD_PRODUCT')"
            icon="i-lucide-plus"
            color="slate"
            variant="outline"
            size="sm"
            @click="addSectionProduct(section)"
          />
        </div>
        <Button
          :label="t('WHATSAPP_TEMPLATES.PARSER.ADD_SECTION')"
          icon="i-lucide-plus"
          color="slate"
          variant="outline"
          size="sm"
          :disabled="processedParams.catalog.sections.length >= 10"
          @click="addProductSection"
        />
      </div>
      <div v-if="productCarouselComponent" class="grid gap-3 mb-4">
        <p class="text-sm font-semibold">
          {{ t('WHATSAPP_TEMPLATES.PARSER.CAROUSEL_PRODUCTS') }}
        </p>
        <div
          v-for="(card, cardIndex) in processedParams.carousel.cards"
          :key="`product-card-${cardIndex}`"
          class="grid gap-2 p-3 border rounded-lg border-n-strong"
        >
          <div class="flex items-center gap-2">
            <Input
              v-model="card.product_retailer_id"
              type="text"
              class="flex-1"
              :placeholder="
                t('WHATSAPP_TEMPLATES.PARSER.CARD_PRODUCT_ID', {
                  number: cardIndex + 1,
                })
              "
            />
            <Button
              icon="i-lucide-trash-2"
              color="slate"
              variant="ghost"
              size="sm"
              :disabled="processedParams.carousel.cards.length <= 2"
              :aria-label="t('WHATSAPP_TEMPLATES.PARSER.REMOVE_PRODUCT')"
              @click="removeProductCard(cardIndex)"
            />
          </div>
          <Input
            v-if="productCarouselHasDynamicUrl"
            v-model="card.url_parameter"
            type="text"
            :placeholder="t('WHATSAPP_TEMPLATES.PARSER.BUTTON_PARAMETER')"
          />
        </div>
        <Button
          :label="t('WHATSAPP_TEMPLATES.PARSER.ADD_PRODUCT_CARD')"
          icon="i-lucide-plus"
          color="slate"
          variant="outline"
          size="sm"
          :disabled="processedParams.carousel.cards.length >= 10"
          @click="addProductCard"
        />
      </div>
      <p
        v-if="v$.$dirty && isFormInvalid"
        class="p-2.5 text-center rounded-md bg-n-ruby-9/20 text-n-ruby-9"
      >
        {{ $t('WHATSAPP_TEMPLATES.PARSER.FORM_ERROR_MESSAGE') }}
      </p>
    </div>

    <slot
      name="actions"
      :send-message="sendMessage"
      :reset-template="resetTemplate"
      :go-back="goBack"
      :is-valid="!isFormInvalid"
      :disabled="isFormInvalid"
    />
  </div>
</template>
