import Restaurant
import SantapCore

public typealias GetFavoritesUseCase = any UseCase<Void, [RestaurantModel]>
public typealias UpdateFavoriteUseCase = any UseCase<FavoriteUpdate, Bool>
