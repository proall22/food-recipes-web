<template>
	<div class="py-8">
		<div class="max-w-2xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="text-center">
				<div v-if="loading" class="animate-pulse">
					<div class="w-16 h-16 bg-gray-300 rounded-full mx-auto mb-4"></div>
					<div class="h-6 bg-gray-300 rounded mb-2"></div>
					<div class="h-4 bg-gray-300 rounded w-3/4 mx-auto"></div>
				</div>

				<div v-else-if="paymentStatus === 'success'" class="text-center">
					<div class="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
						<CheckCircleIcon class="w-10 h-10 text-green-600" />
					</div>
					<h1 class="text-3xl font-bold text-gray-900 mb-4">Payment Successful!</h1>
					<p class="text-xl text-gray-600 mb-8">
						Thank you for your purchase. You now have access to the premium recipe.
					</p>
					<div class="space-y-4">
						<NuxtLink :to="`/recipes/${recipeId}`" class="btn-primary inline-block">
							View Recipe
						</NuxtLink>
						<NuxtLink to="/dashboard" class="btn-secondary inline-block ml-4">
							Go to Dashboard
						</NuxtLink>
					</div>
				</div>

				<div v-else-if="paymentStatus === 'failed'" class="text-center">
					<div class="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
						<XCircleIcon class="w-10 h-10 text-red-600" />
					</div>
					<h1 class="text-3xl font-bold text-gray-900 mb-4">Payment Failed</h1>
					<p class="text-xl text-gray-600 mb-8">
						Unfortunately, your payment could not be processed. Please try again.
					</p>
					<div class="space-y-4">
						<NuxtLink :to="`/recipes/${recipeId}/purchase`" class="btn-primary inline-block">
							Try Again
						</NuxtLink>
						<NuxtLink :to="`/recipes/${recipeId}`" class="btn-secondary inline-block ml-4">
							Back to Recipe
						</NuxtLink>
					</div>
				</div>

				<div v-else class="text-center">
					<div class="w-16 h-16 bg-yellow-100 rounded-full flex items-center justify-center mx-auto mb-4">
						<ClockIcon class="w-10 h-10 text-yellow-600" />
					</div>
					<h1 class="text-3xl font-bold text-gray-900 mb-4">Payment Pending</h1>
					<p class="text-xl text-gray-600 mb-8">
						Your payment is being processed. Please wait a moment.
					</p>
					<button @click="checkPaymentStatus" class="btn-primary" :disabled="checking">
						{{ checking ? 'Checking...' : 'Check Status' }}
					</button>
				</div>
			</div>
		</div>
	</div>
</template>

<script setup>
import { CheckCircleIcon, XCircleIcon, ClockIcon } from "@heroicons/vue/24/outline";
import { usePayments } from "~/composables/usePayments";
import { useNotifications } from "~/composables/useNotifications";

const route = useRoute();
const { verifyPayment } = usePayments();
const { notifyRecipePurchased } = useNotifications();
const { user } = useAuth();

const loading = ref(true);
const checking = ref(false);
const paymentStatus = ref(null);
const transactionId = ref(null);
const recipeId = ref(null);

onMounted(async () => {
	// Get transaction reference from URL parameters
	transactionId.value = route.query.tx_ref || route.query.transaction_id;
	recipeId.value = route.query.recipe_id;

	if (transactionId.value) {
		await verifyPaymentStatus();
	} else {
		paymentStatus.value = 'failed';
		loading.value = false;
	}
});

const verifyPaymentStatus = async () => {
	try {
		const result = await verifyPayment(transactionId.value);
		
		paymentStatus.value = result.success ? 'success' : 'failed';
		
		if (result.success && recipeId.value && user.value) {
			// Send notification to recipe owner
			await notifyRecipePurchased(recipeId.value, user.value.id, parseFloat(result.amount));
		}
	} catch (error) {
		console.error("Payment verification failed:", error);
		paymentStatus.value = 'failed';
	} finally {
		loading.value = false;
	}
};

const checkPaymentStatus = async () => {
	checking.value = true;
	await verifyPaymentStatus();
	checking.value = false;
};

// Meta tags
useHead({
	title: "Payment Status - RecipeHub",
	meta: [
		{ name: "description", content: "Payment processing status" },
	],
});
</script>