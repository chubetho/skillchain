<template>
  <div class="flex items-center">
    <slot name="parent">
      <span class="mr-1 font-bold">

        eth
        <span class="tabular-nums"><slot /></span>
      </span>
    </slot>
    <Etherum class="fill-primary -mt-0.5" />
  </div>
</template>
