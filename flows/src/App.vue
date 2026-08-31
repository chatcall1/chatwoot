<script setup>
import { ref } from 'vue';
import FlowList from './views/FlowList.vue';
import FlowEditor from './views/FlowEditor.vue';

const activeFlow = ref(null);

const openEditor = flow => {
  activeFlow.value = flow;
};

const closeEditor = () => {
  activeFlow.value = null;
};
</script>

<template>
  <main class="h-full min-h-0 bg-n-background">
    <FlowEditor v-if="activeFlow" :flow="activeFlow" @close="closeEditor" />
    <FlowList v-else @open="openEditor" />
  </main>
</template>
