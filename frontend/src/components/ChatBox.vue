<script setup lang="ts">
const { dir = 'left' } = defineProps<{
  dir?: 'left' | 'right'
  parentClass?: string
}>()
</script>

<template>
  <div class="flex" :class="{ 'justify-end': dir === 'right' }">
    <div class="w-2/3" :class="{ 'flex justify-end': dir === 'right' }">
      <div class="rounded-md bg-secondary w-fit relative">
        <div :class="parentClass ?? 'px-3 py-1 tracking-wide min-w-[100px]'">
          <slot />
        </div>
        <slot name="timestamp" />
      </div>
    </div>
  </div>
</template>
