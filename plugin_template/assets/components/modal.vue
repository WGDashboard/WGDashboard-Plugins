<script setup lang="ts">
const s = store()

</script>

<template>
	<div id="modal" class="p-3">
		<div class="card w-100 h-100 rounded-4">
			<div class="card-header d-flex">
				<a role="button"
				   @click="s.modal = false"
				   class="ms-auto text-white">
					<h4 class="mb-0"><i class="bi bi-x-lg"></i></h4>
				</a>
			</div>
			<div class="card-body flex-grow-1 p-0">
				<iframe
					class="w-100 h-100 rounded-bottom-4"
					:src="s.modalSrc"></iframe>
			</div>
		</div>
	</div>
</template>

<style scoped>
#modal{
	height: 100dvh;
	width: 100dvw;
	position: fixed;
	background: #00000050;
	top: 0;
	left: 0;
	z-index: 10000;
	backdrop-filter: blur(8px);
}
</style>