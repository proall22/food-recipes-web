export const useNotifications = () => {
	const { user, token } = useAuth();
	const config = useRuntimeConfig();

	// Email notification types
	const EMAIL_TYPES = {
		WELCOME: 'welcome',
		RECIPE_LIKED: 'recipe_liked',
		RECIPE_COMMENTED: 'recipe_commented',
		RECIPE_RATED: 'recipe_rated',
		RECIPE_PURCHASED: 'recipe_purchased',
		NEW_FOLLOWER: 'new_follower',
		WEEKLY_DIGEST: 'weekly_digest',
	};

	const sendEmailNotification = async (
		recipientEmail: string,
		type: string,
		data: Record<string, any>
	) => {
		try {
			await $fetch(`${config.public.backendUrl}/api/v1/notifications/email`, {
				method: "POST",
				headers: {
					"Content-Type": "application/json",
					Authorization: `Bearer ${token.value}`,
				},
				body: JSON.stringify({
					recipient_email: recipientEmail,
					type,
					data,
				}),
			});
		} catch (error) {
			console.error("Failed to send email notification:", error);
		}
	};

	// Notification for when someone likes a recipe
	const notifyRecipeLiked = async (recipeId: string, likedByUserId: string) => {
		if (!user.value) return;

		try {
			// Get recipe and owner details
			const { data } = await $fetch("/api/graphql", {
				method: "POST",
				headers: {
					"Content-Type": "application/json",
					Authorization: `Bearer ${token.value}`,
				},
				body: {
					query: `
						query GetRecipeForNotification($recipe_id: uuid!, $user_id: uuid!) {
							recipes_by_pk(id: $recipe_id) {
								id
								title
								user {
									id
									email
									full_name
								}
							}
							users_by_pk(id: $user_id) {
								id
								full_name
								username
							}
						}
					`,
					variables: {
						recipe_id: recipeId,
						user_id: likedByUserId,
					},
				},
			});

			const recipe = data?.recipes_by_pk;
			const likedByUser = data?.users_by_pk;

			if (recipe && likedByUser && recipe.user.id !== likedByUserId) {
				await sendEmailNotification(
					recipe.user.email,
					EMAIL_TYPES.RECIPE_LIKED,
					{
						recipe_title: recipe.title,
						recipe_id: recipe.id,
						liked_by_name: likedByUser.full_name,
						liked_by_username: likedByUser.username,
					}
				);
			}
		} catch (error) {
			console.error("Failed to send recipe liked notification:", error);
		}
	};

	// Notification for when someone comments on a recipe
	const notifyRecipeCommented = async (recipeId: string, commentedByUserId: string, comment: string) => {
		if (!user.value) return;

		try {
			const { data } = await $fetch("/api/graphql", {
				method: "POST",
				headers: {
					"Content-Type": "application/json",
					Authorization: `Bearer ${token.value}`,
				},
				body: {
					query: `
						query GetRecipeForCommentNotification($recipe_id: uuid!, $user_id: uuid!) {
							recipes_by_pk(id: $recipe_id) {
								id
								title
								user {
									id
									email
									full_name
								}
							}
							users_by_pk(id: $user_id) {
								id
								full_name
								username
							}
						}
					`,
					variables: {
						recipe_id: recipeId,
						user_id: commentedByUserId,
					},
				},
			});

			const recipe = data?.recipes_by_pk;
			const commentedByUser = data?.users_by_pk;

			if (recipe && commentedByUser && recipe.user.id !== commentedByUserId) {
				await sendEmailNotification(
					recipe.user.email,
					EMAIL_TYPES.RECIPE_COMMENTED,
					{
						recipe_title: recipe.title,
						recipe_id: recipe.id,
						commented_by_name: commentedByUser.full_name,
						commented_by_username: commentedByUser.username,
						comment: comment.substring(0, 100) + (comment.length > 100 ? '...' : ''),
					}
				);
			}
		} catch (error) {
			console.error("Failed to send recipe commented notification:", error);
		}
	};

	// Notification for when someone rates a recipe
	const notifyRecipeRated = async (recipeId: string, ratedByUserId: string, rating: number) => {
		if (!user.value) return;

		try {
			const { data } = await $fetch("/api/graphql", {
				method: "POST",
				headers: {
					"Content-Type": "application/json",
					Authorization: `Bearer ${token.value}`,
				},
				body: {
					query: `
						query GetRecipeForRatingNotification($recipe_id: uuid!, $user_id: uuid!) {
							recipes_by_pk(id: $recipe_id) {
								id
								title
								user {
									id
									email
									full_name
								}
							}
							users_by_pk(id: $user_id) {
								id
								full_name
								username
							}
						}
					`,
					variables: {
						recipe_id: recipeId,
						user_id: ratedByUserId,
					},
				},
			});

			const recipe = data?.recipes_by_pk;
			const ratedByUser = data?.users_by_pk;

			if (recipe && ratedByUser && recipe.user.id !== ratedByUserId) {
				await sendEmailNotification(
					recipe.user.email,
					EMAIL_TYPES.RECIPE_RATED,
					{
						recipe_title: recipe.title,
						recipe_id: recipe.id,
						rated_by_name: ratedByUser.full_name,
						rated_by_username: ratedByUser.username,
						rating,
					}
				);
			}
		} catch (error) {
			console.error("Failed to send recipe rated notification:", error);
		}
	};

	// Notification for when someone purchases a recipe
	const notifyRecipePurchased = async (recipeId: string, purchasedByUserId: string, amount: number) => {
		if (!user.value) return;

		try {
			const { data } = await $fetch("/api/graphql", {
				method: "POST",
				headers: {
					"Content-Type": "application/json",
					Authorization: `Bearer ${token.value}`,
				},
				body: {
					query: `
						query GetRecipeForPurchaseNotification($recipe_id: uuid!, $user_id: uuid!) {
							recipes_by_pk(id: $recipe_id) {
								id
								title
								user {
									id
									email
									full_name
								}
							}
							users_by_pk(id: $user_id) {
								id
								full_name
								username
								email
							}
						}
					`,
					variables: {
						recipe_id: recipeId,
						user_id: purchasedByUserId,
					},
				},
			});

			const recipe = data?.recipes_by_pk;
			const purchasedByUser = data?.users_by_pk;

			if (recipe && purchasedByUser) {
				// Notify recipe owner
				if (recipe.user.id !== purchasedByUserId) {
					await sendEmailNotification(
						recipe.user.email,
						EMAIL_TYPES.RECIPE_PURCHASED,
						{
							recipe_title: recipe.title,
							recipe_id: recipe.id,
							purchased_by_name: purchasedByUser.full_name,
							purchased_by_username: purchasedByUser.username,
							amount,
						}
					);
				}

				// Send purchase confirmation to buyer
				await sendEmailNotification(
					purchasedByUser.email,
					'purchase_confirmation',
					{
						recipe_title: recipe.title,
						recipe_id: recipe.id,
						amount,
						seller_name: recipe.user.full_name,
					}
				);
			}
		} catch (error) {
			console.error("Failed to send recipe purchased notification:", error);
		}
	};

	// Send welcome email to new users
	const sendWelcomeEmail = async (userEmail: string, userName: string) => {
		try {
			await sendEmailNotification(
				userEmail,
				EMAIL_TYPES.WELCOME,
				{
					user_name: userName,
				}
			);
		} catch (error) {
			console.error("Failed to send welcome email:", error);
		}
	};

	return {
		EMAIL_TYPES,
		sendEmailNotification,
		notifyRecipeLiked,
		notifyRecipeCommented,
		notifyRecipeRated,
		notifyRecipePurchased,
		sendWelcomeEmail,
	};
};