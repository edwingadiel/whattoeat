export type RecommendationRequest = {
  targetCalories: number;
  targetProtein: number;
  targetCarbs?: number | null;
  targetFat?: number | null;
  context?: string | null;
};

export type CandidateItem = {
  id: string;
  restaurantId: string;
  name: string;
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  contexts: string[];
  popularityPrior: number;
};

const closeness = (value: number, target: number) => {
  if (target <= 0) return 0;
  return Math.max(0, 1 - Math.abs(value - target) / target);
};

export const scoreCandidates = (
  items: CandidateItem[],
  request: RecommendationRequest,
  favoriteIds: string[],
  likedIds: string[],
  expanded = false
) => {
  const calorieTolerance = expanded ? 0.15 : 0.10;
  const proteinShortfall = expanded ? 8 : 5;

  return items
    .filter((item) => {
      const minCalories = request.targetCalories * (1 - calorieTolerance);
      const maxCalories = request.targetCalories * (1 + calorieTolerance);
      return (
        item.calories >= minCalories &&
        item.calories <= maxCalories &&
        item.protein >= request.targetProtein - proteinShortfall
      );
    })
    .map((item) => {
      const calorieScore = closeness(item.calories, request.targetCalories);
      const proteinScore = closeness(item.protein, request.targetProtein);
      const contextScore = request.context
        ? item.contexts.includes(request.context)
          ? 1
          : 0.35
        : 1;
      const preferenceScore = favoriteIds.includes(item.id)
        ? 0.85
        : likedIds.includes(item.id)
        ? 0.7
        : 0.45;

      const total =
        calorieScore * 0.4 +
        proteinScore * 0.35 +
        contextScore * 0.1 +
        preferenceScore * 0.1 +
        item.popularityPrior * 0.05;

      return {
        ...item,
        finalScore: total,
        isNearMatch: expanded
      };
    })
    .sort((a, b) => b.finalScore - a.finalScore);
};
