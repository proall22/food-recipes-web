import { useQuery, useMutation } from "@vue/apollo-composable";
import gql from "graphql-tag";

// GraphQL Queries
export const GET_RECIPES = gql`
	query GetRecipes(
		$limit: Int!
		$offset: Int!
		$where: recipes_bool_exp
		$order_by: [recipes_order_by!]
	) {
		recipes(
			limit: $limit
			offset: $offset
			where: $where
			order_by: $order_by
		) {
			id
			title
			description
			prep_time
			cook_time
			difficulty
			featured_image_url
			is_premium
			price
			created_at
			average_rating
			total_likes
			total_comments
			user {
				id
				username
				full_name
				avatar_url
			}
			category {
				id
				name
				slug
			}
		}
		recipes_aggregate(where: $where) {
			aggregate {
				count
			}
		}
	}
`;

export const GET_RECIPE_BY_ID = gql`
	query GetRecipeById($id: uuid!) {
		recipes_by_pk(id: $id) {
			id
			title
			description
			prep_time
			cook_time
			servings
			difficulty
			featured_image_url
			is_premium
			price
			is_published
			created_at
			updated_at
			average_rating
			total_likes
			total_comments
			user {
				id
				username
				full_name
				avatar_url
				bio
			}
			category {
				id
				name
				slug
			}
			ingredients {
				id
				name
				amount
				unit
				notes
			}
			steps {
				id
				step_number
				instruction
				image_url
			}
			images {
				id
				image_url
				is_featured
				caption
			}
		}
	}
`;

export const GET_USER_RECIPE_INTERACTIONS = gql`
	query GetUserRecipeInteractions($user_id: uuid!, $recipe_id: uuid!) {
		likes(where: { user_id: { _eq: $user_id }, recipe_id: { _eq: $recipe_id } }) {
			id
		}
		bookmarks(where: { user_id: { _eq: $user_id }, recipe_id: { _eq: $recipe_id } }) {
			id
		}
		ratings(where: { user_id: { _eq: $user_id }, recipe_id: { _eq: $recipe_id } }) {
			id
			rating
		}
		purchases(where: { user_id: { _eq: $user_id }, recipe_id: { _eq: $recipe_id }, status: { _eq: "completed" } }) {
			id
		}
	}
`;

export const GET_RECIPE_COMMENTS = gql`
	query GetRecipeComments($recipe_id: uuid!, $limit: Int!, $offset: Int!) {
		comments(
			where: { recipe_id: { _eq: $recipe_id }, parent_id: { _is_null: true } }
			order_by: { created_at: desc }
			limit: $limit
			offset: $offset
		) {
			id
			content
			created_at
			updated_at
			user {
				id
				username
				full_name
				avatar_url
			}
			replies: comments(order_by: { created_at: asc }) {
				id
				content
				created_at
				user {
					id
					username
					full_name
					avatar_url
				}
			}
		}
	}
`;

export const GET_CATEGORIES = gql`
	query GetCategories {
		categories(order_by: { name: asc }) {
			id
			name
			description
			icon
			slug
		}
	}
`;

export const GET_POPULAR_RECIPES = gql`
	query GetPopularRecipes($limit: Int!) {
		recipes(limit: $limit, order_by: [{ created_at: desc }]) {
			id
			title
			description
			prep_time
			cook_time
			difficulty
			featured_image_url
			is_premium
			price
			created_at
			average_rating
			total_likes
			total_comments
			user {
				id
				username
				full_name
				avatar_url
			}
			category {
				id
				name
				slug
			}
		}
	}
`;

export const SEARCH_RECIPES = gql`
	query SearchRecipes($search_term: String!) {
		recipes(
			where: {
				_or: [
					{ title: { _ilike: $search_term } }
					{ description: { _ilike: $search_term } }
				]
			}
		) {
			id
			title
			description
			prep_time
			cook_time
			difficulty
			featured_image_url
			is_premium
			price
			created_at
			average_rating
			total_likes
			total_comments
			user {
				id
				username
				full_name
				avatar_url
			}
			category {
				id
				name
				slug
			}
		}
	}
`;

export const CREATE_RECIPE = gql`
	mutation CreateRecipe($recipe: recipes_insert_input!) {
		insert_recipes_one(object: $recipe) {
			id
			title
			created_at
		}
	}
`;

export const LIKE_RECIPE = gql`
	mutation LikeRecipe($recipe_id: uuid!) {
		insert_likes_one(object: { recipe_id: $recipe_id }) {
			id
		}
	}
`;

export const UNLIKE_RECIPE = gql`
	mutation UnlikeRecipe($recipe_id: uuid!) {
		delete_likes(where: { recipe_id: { _eq: $recipe_id } }) {
			affected_rows
		}
	}
`;

export const GET_USER_LIKES = gql`
	query GetUserLikes($user_id: uuid!) {
		likes(where: { user_id: { _eq: $user_id } }) {
			id
			recipe_id
		}
	}
`;

// Composables for using GraphQL operations
export const useRecipes = () => {
	const getRecipes = (variables = { limit: 10, offset: 0 }) => {
		return useQuery(GET_RECIPES, variables, {
			errorPolicy: "all",
		});
	};

	const getRecipeById = (id) => {
		return useQuery(
			GET_RECIPE_BY_ID,
			{ id },
			{
				errorPolicy: "all",
				skip: !id,
			}
		);
	};

	const getPopularRecipes = (limit = 6) => {
		return useQuery(
			GET_POPULAR_RECIPES,
			{ limit },
			{
				errorPolicy: "all",
			}
		);
	};

	const searchRecipes = (searchTerm: string) => {
		return useQuery(
			SEARCH_RECIPES,
			{ search_term: `%${searchTerm}%` },
			{
				errorPolicy: "all",
			}
		);
	};

	const createRecipe = () => useMutation(CREATE_RECIPE);
	const deleteRecipe = () => useMutation(DELETE_RECIPE);

	return {
		getRecipes,
		getRecipeById,
		getPopularRecipes,
		searchRecipes,
		createRecipe,
		deleteRecipe,
	};
};

export const useRecipeInteractions = () => {
	const likeRecipe = () => useMutation(LIKE_RECIPE);
	const unlikeRecipe = () => useMutation(UNLIKE_RECIPE);
	const bookmarkRecipe = () => useMutation(BOOKMARK_RECIPE);
	const removeBookmark = () => useMutation(REMOVE_BOOKMARK);
	const addComment = () => useMutation(ADD_COMMENT);
	const rateRecipe = () => useMutation(RATE_RECIPE);

	const getUserLikes = (userId: string) => {
		return useQuery(
			GET_USER_LIKES,
			{ user_id: userId },
			{
				errorPolicy: "all",
				skip: !userId,
			}
		);
	};

	const getUserRecipeInteractions = (userId: string, recipeId: string) => {
		return useQuery(
			GET_USER_RECIPE_INTERACTIONS,
			{ user_id: userId, recipe_id: recipeId },
			{
				errorPolicy: "all",
				skip: !userId || !recipeId,
			}
		);
	};

	const getRecipeComments = (recipeId: string, limit = 10, offset = 0) => {
		return useQuery(
			GET_RECIPE_COMMENTS,
			{ recipe_id: recipeId, limit, offset },
			{
				errorPolicy: "all",
				skip: !recipeId,
			}
		);
	};

	return {
		likeRecipe,
		unlikeRecipe,
		bookmarkRecipe,
		removeBookmark,
		addComment,
		rateRecipe,
		getUserLikes,
		getUserRecipeInteractions,
		getRecipeComments,
	};
};

export const useCategories = () => {
	const getCategories = () => {
		return useQuery(
			GET_CATEGORIES,
			{},
			{
				errorPolicy: "all",
			}
		);
	};

	return {
		getCategories,
	};
};
