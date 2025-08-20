export const usePayments = () => {
	const { token, user } = useAuth();
	const config = useRuntimeConfig();
	const processing = ref(false);

	const initializePayment = async (paymentData: {
		recipe_id: string;
		amount: number;
		email: string;
		phone: string;
		first_name: string;
		last_name: string;
		callback_url?: string;
		return_url?: string;
	}) => {
		processing.value = true;

		try {
			const response = await $fetch(`${config.public.backendUrl}/api/v1/payments/initialize`, {
				method: "POST",
				headers: {
					"Content-Type": "application/json",
					Authorization: `Bearer ${token.value}`,
				},
				body: JSON.stringify({
					recipe_id: paymentData.recipe_id,
					amount: paymentData.amount,
					callback_url: paymentData.callback_url || `${window.location.origin}/payment/callback`,
					return_url: paymentData.return_url || `${window.location.origin}/recipes/${paymentData.recipe_id}`,
				}),
			});

			if (response.checkout_url) {
				// Redirect to Chapa checkout
				window.location.href = response.checkout_url;
				return {
					success: true,
					checkout_url: response.checkout_url,
					transaction_id: response.transaction_id,
				};
			} else {
				throw new Error('No checkout URL received');
			}
		} catch (error: any) {
			console.error("Payment initialization failed:", error);
			
			let errorMessage = "Payment initialization failed. Please try again.";
			if (error.data?.error) {
				errorMessage = error.data.error;
			} else if (error.message) {
				errorMessage = error.message;
			}

			return {
				success: false,
				error: errorMessage,
			};
		} finally {
			processing.value = false;
		}
	};

	const verifyPayment = async (transactionId: string) => {
		try {
			const response = await $fetch(`${config.public.backendUrl}/api/v1/payments/verify`, {
				method: "POST",
				headers: {
					"Content-Type": "application/json",
					Authorization: `Bearer ${token.value}`,
				},
				body: JSON.stringify({
					tx_ref: transactionId,
				}),
			});

			return {
				success: response.status === 'success',
				status: response.status,
				transaction_id: response.transaction_id,
				amount: response.amount,
			};
		} catch (error: any) {
			console.error("Payment verification failed:", error);
			return {
				success: false,
				error: error.message || "Payment verification failed",
			};
		}
	};

	const getPaymentStatus = async (transactionId: string) => {
		try {
			const response = await $fetch(`${config.public.backendUrl}/api/v1/payments/status/${transactionId}`, {
				method: "GET",
				headers: {
					Authorization: `Bearer ${token.value}`,
				},
			});

			return response;
		} catch (error: any) {
			console.error("Failed to get payment status:", error);
			throw error;
		}
	};

	// Check if user has purchased a recipe
	const checkRecipePurchase = async (recipeId: string) => {
		if (!user.value) return false;

		try {
			const { data } = await $fetch("/api/graphql", {
				method: "POST",
				headers: {
					"Content-Type": "application/json",
					Authorization: `Bearer ${token.value}`,
				},
				body: {
					query: `
						query CheckRecipePurchase($user_id: uuid!, $recipe_id: uuid!) {
							purchases(
								where: { 
									user_id: { _eq: $user_id }, 
									recipe_id: { _eq: $recipe_id }, 
									status: { _eq: "completed" } 
								}
							) {
								id
								status
								created_at
							}
						}
					`,
					variables: {
						user_id: user.value.id,
						recipe_id: recipeId,
					},
				},
			});

			return data?.purchases?.length > 0;
		} catch (error) {
			console.error("Failed to check recipe purchase:", error);
			return false;
		}
	};

	return {
		processing: readonly(processing),
		initializePayment,
		verifyPayment,
		getPaymentStatus,
		checkRecipePurchase,
	};
};