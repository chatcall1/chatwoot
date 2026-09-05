<script setup>
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  state: { type: Object, required: true },
  direction: { type: String, required: true },
  authenticationPreviewBody: { type: String, required: true },
  authenticationPreviewFooter: { type: String, required: true },
  authenticationPreviewButton: { type: String, required: true },
  templateFormat: { type: String, required: true },
  catalogFormat: { type: String, required: true },
  productTemplateType: { type: String, required: true },
  productCarouselButtonType: { type: String, required: true },
  productCarouselUrl: { type: Object, required: true },
  activeCardIndex: { type: Number, required: true },
  carouselActionByValue: { type: Object, required: true },
});
defineEmits(['selectCard', 'navigateCard', 'setCardElement']);
const { t } = useI18n();
</script>

<template>
  <div
    class="flex flex-col items-center gap-3 order-1 lg:order-2 lg:sticky lg:top-0"
  >
    <p class="text-sm font-medium text-n-slate-12">
      {{ t('WHATSAPP_TEMPLATE_BUILDER.PREVIEW.TITLE') }}
    </p>
    <p class="-mt-2 text-xs text-center text-n-slate-10">
      {{ t('WHATSAPP_TEMPLATE_BUILDER.PREVIEW.DESCRIPTION') }}
    </p>
    <div
      class="relative w-[20rem] h-[39rem] p-[0.45rem] border-[0.2rem] border-[#d6d8da] rounded-[2.8rem] bg-[#f7f7f7] shadow-[0_1.5rem_3rem_rgba(31,41,55,0.18)]"
    >
      <div
        class="absolute z-20 w-24 h-5 -translate-x-1/2 bg-[#f7f7f7] rounded-b-2xl top-1 left-1/2"
      />
      <div
        class="flex flex-col h-full overflow-hidden rounded-[2.25rem] bg-[#efeae2]"
        :dir="direction"
      >
        <div
          class="flex items-center justify-between h-7 px-5 text-[0.65rem] font-semibold text-[#111827] bg-[#f7f9fa]"
        >
          <span>{{ t('WHATSAPP_TEMPLATE_BUILDER.PREVIEW.TIME') }}</span>
          <span class="flex items-center gap-1" dir="ltr">
            <Icon icon="i-lucide-signal" class="size-3" />
            <span>{{ t('WHATSAPP_TEMPLATE_BUILDER.PREVIEW.NETWORK') }}</span>
            <Icon icon="i-lucide-battery-full" class="size-3.5" />
          </span>
        </div>
        <div
          class="flex items-center gap-2 px-3 py-2.5 border-b border-[#dde2e5] bg-[#f7f9fa] text-[#111827]"
        >
          <Icon icon="i-lucide-chevron-left" class="size-5 text-[#55747d]" />
          <span
            class="grid rounded-full size-10 shrink-0 place-items-center bg-[#dff5f2] text-xs font-semibold text-[#08776d] ring-1 ring-[#b7e2dc]"
          >
            {{ t('WHATSAPP_TEMPLATE_BUILDER.PREVIEW.AVATAR') }}
          </span>
          <span class="flex flex-col min-w-0 grow">
            <span class="text-sm font-semibold truncate">
              {{ t('WHATSAPP_TEMPLATE_BUILDER.PREVIEW.BUSINESS') }}
            </span>
            <span class="text-[0.6rem] text-[#667781]">
              {{ t('WHATSAPP_TEMPLATE_BUILDER.PREVIEW.BUSINESS_SUBTITLE') }}
            </span>
          </span>
          <Icon icon="i-lucide-store" class="size-5 text-[#55747d]" />
          <Icon icon="i-lucide-more-vertical" class="size-5 text-[#55747d]" />
        </div>
        <div
          class="flex flex-col flex-1 gap-3 p-3 bg-[#efeae2] bg-[radial-gradient(circle_at_20%_20%,rgba(120,103,82,0.08)_1px,transparent_1px)] bg-[size:1rem_1rem]"
        >
          <div
            class="self-center px-2.5 py-1 text-[0.6rem] rounded-md shadow-sm bg-white/90 text-[#667781]"
          >
            {{ t('WHATSAPP_TEMPLATE_BUILDER.PREVIEW.TODAY') }}
          </div>
          <div
            v-if="state.category === 'AUTHENTICATION'"
            class="self-start max-w-[92%] overflow-hidden rounded-xl rounded-ss-sm bg-white shadow-sm text-xs text-[#111827]"
            :dir="direction"
          >
            <div class="p-3">
              <p class="leading-5">
                {{ authenticationPreviewBody }}
              </p>
              <p
                v-if="state.authenticationExpirationEnabled"
                class="mt-2 text-[0.65rem] text-[#667781]"
              >
                {{ authenticationPreviewFooter }}
              </p>
              <span class="block mt-2 text-[0.58rem] text-end text-[#8696a0]">
                {{ t('WHATSAPP_TEMPLATE_BUILDER.PREVIEW.TIME') }}
              </span>
            </div>
            <div
              class="px-3 py-2.5 border-t border-[#e9edef] text-center font-medium text-[#00a884]"
            >
              {{ authenticationPreviewButton }}
            </div>
          </div>
          <div
            v-else-if="
              templateFormat === 'catalog' &&
              catalogFormat === 'product_carousel'
            "
            class="flex flex-col gap-2 overflow-hidden"
          >
            <div
              class="self-start max-w-[92%] p-3 text-xs bg-white shadow-sm rounded-xl rounded-ss-sm text-[#111827]"
            >
              {{ state.body || t('WHATSAPP_TEMPLATE_BUILDER.PREVIEW.BODY') }}
            </div>
            <div class="flex gap-2 overflow-hidden">
              <div
                v-for="index in 2"
                :key="index"
                class="w-44 overflow-hidden text-start bg-white border border-[#c9d1d5] shrink-0 rounded-xl shadow-sm"
              >
                <div
                  class="grid h-24 place-items-center bg-[#e9edef] text-[#8696a0]"
                >
                  <Icon icon="i-lucide-package" class="size-7" />
                </div>
                <div class="p-3 text-xs text-[#111827]">
                  <p class="font-medium">
                    {{
                      t('WHATSAPP_TEMPLATE_BUILDER.CATALOG.PREVIEW.PRODUCT', {
                        n: index,
                      })
                    }}
                  </p>
                  <p class="mt-1 text-[0.65rem] text-[#667781]">
                    {{ t('WHATSAPP_TEMPLATE_BUILDER.CATALOG.PREVIEW.PRICE') }}
                  </p>
                </div>
                <div
                  class="px-3 py-2 border-t border-[#e9edef] text-center text-xs font-medium text-[#00a884]"
                >
                  {{
                    productCarouselButtonType === 'SPM'
                      ? t(
                          'WHATSAPP_TEMPLATE_BUILDER.CATALOG.PREVIEW.VIEW_PRODUCT'
                        )
                      : productCarouselUrl.text ||
                        t(
                          'WHATSAPP_TEMPLATE_BUILDER.CATALOG.BUTTONS.URL_TEXT_PLACEHOLDER'
                        )
                  }}
                </div>
              </div>
            </div>
          </div>
          <div
            v-else-if="templateFormat === 'catalog'"
            class="self-start max-w-[92%] overflow-hidden rounded-xl rounded-ss-sm bg-white shadow-sm text-xs text-[#111827]"
          >
            <div
              v-if="
                catalogFormat === 'catalog_template' ||
                productTemplateType === 'spm'
              "
              class="grid h-28 place-items-center bg-[#e9edef] text-[#8696a0]"
            >
              <span class="flex flex-col items-center gap-2">
                <Icon icon="i-lucide-package" class="size-7" />
                {{
                  t('WHATSAPP_TEMPLATE_BUILDER.CATALOG.PREVIEW.PRODUCT_MEDIA')
                }}
              </span>
            </div>
            <div class="p-3">
              <p>
                {{ state.body || t('WHATSAPP_TEMPLATE_BUILDER.PREVIEW.BODY') }}
              </p>
              <p v-if="state.footer" class="mt-2 text-[0.65rem] text-[#667781]">
                {{ state.footer }}
              </p>
              <span class="block mt-2 text-[0.58rem] text-end text-[#8696a0]">
                {{ t('WHATSAPP_TEMPLATE_BUILDER.PREVIEW.TIME') }}
              </span>
            </div>
            <div
              class="px-3 py-2.5 border-t border-[#e9edef] text-center font-medium text-[#00a884]"
            >
              {{
                catalogFormat === 'catalog_template'
                  ? t('WHATSAPP_TEMPLATE_BUILDER.CATALOG.PREVIEW.VIEW_CATALOG')
                  : productTemplateType === 'mpm'
                    ? t('WHATSAPP_TEMPLATE_BUILDER.CATALOG.PREVIEW.VIEW_ITEMS')
                    : t(
                        'WHATSAPP_TEMPLATE_BUILDER.CATALOG.PREVIEW.VIEW_PRODUCT'
                      )
              }}
            </div>
          </div>
          <div
            v-else-if="templateFormat === 'carousel'"
            class="flex flex-col gap-2 overflow-hidden"
          >
            <div
              class="self-start max-w-[92%] p-3 text-xs bg-white shadow-sm rounded-xl rounded-ss-sm text-[#111827]"
            >
              {{ state.body || t('WHATSAPP_TEMPLATE_BUILDER.PREVIEW.BODY') }}
            </div>
            <div class="relative">
              <div class="overflow-hidden scroll-smooth" :dir="direction">
                <div class="flex gap-2">
                  <button
                    v-for="(card, index) in state.cards"
                    :key="card.id"
                    :ref="element => $emit('setCardElement', card.id, element)"
                    type="button"
                    class="w-44 overflow-hidden text-start bg-white border shrink-0 rounded-xl shadow-sm transition-all duration-200 hover:-translate-y-px hover:shadow-md"
                    :class="
                      index === activeCardIndex
                        ? 'border-[#008f72] ring-2 ring-inset ring-[#00a884] shadow-md'
                        : 'border-[#c9d1d5] hover:border-[#9daab0]'
                    "
                    :dir="direction"
                    @click="$emit('selectCard', index)"
                  >
                    <div
                      class="grid h-24 place-items-center bg-[#e9edef] text-[#8696a0]"
                    >
                      <img
                        v-if="
                          card.mediaUrl &&
                          card.mediaMimeType.startsWith('image/')
                        "
                        :src="card.mediaUrl"
                        class="object-cover w-full h-full"
                      />
                      <video
                        v-else-if="card.mediaUrl"
                        :src="card.mediaUrl"
                        class="object-cover w-full h-full"
                        muted
                      />
                      <Icon
                        v-else
                        :icon="
                          state.carouselMediaType === 'video'
                            ? 'i-lucide-video'
                            : 'i-lucide-image'
                        "
                        class="size-7"
                      />
                    </div>
                    <div
                      v-if="state.carouselTextEnabled"
                      class="p-3 text-xs text-[#111827]"
                    >
                      <p>
                        {{
                          card.body ||
                          t(
                            'WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.CARD_BODY_PREVIEW'
                          )
                        }}
                      </p>
                      <span
                        class="block mt-2 text-[0.58rem] text-end text-[#8696a0]"
                      >
                        {{ t('WHATSAPP_TEMPLATE_BUILDER.PREVIEW.TIME') }}
                      </span>
                    </div>
                    <div
                      v-for="action in state.carouselButtonTypes"
                      :key="action"
                      class="px-3 py-2 border-t border-[#e9edef] text-center text-xs font-medium text-[#00a884]"
                    >
                      {{
                        card.buttons[action].text ||
                        carouselActionByValue[action].label
                      }}
                    </div>
                  </button>
                </div>
              </div>
              <Button
                v-if="activeCardIndex > 0"
                :icon="
                  direction === 'rtl'
                    ? 'i-lucide-chevron-right'
                    : 'i-lucide-chevron-left'
                "
                color="slate"
                size="sm"
                class="absolute z-10 -translate-y-1/2 rounded-full shadow-md top-1/2 start-1"
                :aria-label="
                  t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.PREVIOUS_CARD')
                "
                @click="$emit('navigateCard', -1)"
              />
              <Button
                v-if="activeCardIndex < state.cards.length - 1"
                :icon="
                  direction === 'rtl'
                    ? 'i-lucide-chevron-left'
                    : 'i-lucide-chevron-right'
                "
                color="slate"
                size="sm"
                class="absolute z-10 -translate-y-1/2 rounded-full shadow-md top-1/2 end-1"
                :aria-label="t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.NEXT_CARD')"
                @click="$emit('navigateCard', 1)"
              />
            </div>
          </div>
          <div
            v-else
            class="self-start max-w-[92%] overflow-hidden rounded-xl rounded-ss-sm bg-white shadow-sm text-xs text-[#111827]"
          >
            <div
              v-if="['image', 'video', 'document'].includes(state.headerType)"
              class="flex items-center justify-center h-28 bg-[#e9edef] text-[#8696a0]"
            >
              <img
                v-if="state.headerType === 'image' && state.headerMediaUrl"
                :src="state.headerMediaUrl"
                class="object-cover w-full h-full"
              />
              <span v-else class="flex flex-col items-center gap-2">
                <Icon
                  :icon="
                    state.headerType === 'video'
                      ? 'i-lucide-video'
                      : state.headerType === 'document'
                        ? 'i-lucide-file-text'
                        : 'i-lucide-image'
                  "
                  class="size-6"
                />
                {{
                  state.headerMediaName ||
                  t('WHATSAPP_TEMPLATE_BUILDER.PREVIEW.MEDIA')
                }}
              </span>
            </div>
            <div class="p-3">
              <p
                v-if="state.headerType === 'text' && state.headerText"
                class="mb-2 text-sm font-semibold"
              >
                {{ state.headerText }}
              </p>
              <p class="leading-5 whitespace-pre-wrap">
                {{ state.body || t('WHATSAPP_TEMPLATE_BUILDER.PREVIEW.BODY') }}
              </p>
              <p v-if="state.footer" class="mt-2 text-[0.65rem] text-[#667781]">
                {{ state.footer }}
              </p>
              <span class="block mt-1 text-[0.58rem] text-end text-[#8696a0]">
                {{ t('WHATSAPP_TEMPLATE_BUILDER.PREVIEW.TIME') }}
              </span>
            </div>
            <div
              v-for="button in state.standardButtons"
              :key="button.id"
              class="px-3 py-2.5 border-t border-[#e9edef] text-center font-medium text-[#00a884]"
            >
              {{
                button.type === 'COPY_CODE'
                  ? t('WHATSAPP_TEMPLATE_BUILDER.BUTTONS.TYPES.COPY_CODE')
                  : button.text
              }}
            </div>
          </div>
        </div>
        <div
          class="flex items-center gap-2 px-3 py-2.5 border-t border-[#dde2e5] bg-[#f7f9fa] text-[#8696a0]"
        >
          <Icon icon="i-lucide-plus" class="size-5" />
          <div
            class="flex items-center flex-1 gap-2 px-3 py-2 rounded-full bg-[#eef1f3]"
          >
            <Icon icon="i-lucide-smile" class="size-4" />
            <span class="text-[0.65rem] grow">
              {{ t('WHATSAPP_TEMPLATE_BUILDER.PREVIEW.MESSAGE') }}
            </span>
            <Icon icon="i-lucide-paperclip" class="size-4" />
            <Icon icon="i-lucide-camera" class="size-4" />
          </div>
          <Icon icon="i-lucide-mic" class="size-5" />
        </div>
      </div>
    </div>
  </div>
</template>
