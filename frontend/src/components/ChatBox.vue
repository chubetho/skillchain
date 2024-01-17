<script setup lang="ts">
const { dir = 'left' } = defineProps<{
  dir?: 'left' | 'right'
  parentClass?: string
}>()
</script>

<template>
  <div class="flex" :class="{ 'justify-end': dir === 'right' }">
    <div class="w-2/3" :class="{ 'flex justify-end': dir === 'right' }">
      <div class="rounded-md bg-secondary w-fit">
        <div :class="parentClass ?? 'px-3 py-1'">
          <slot />
        </div>
      </div>
    </div>
  </div>
</template>
