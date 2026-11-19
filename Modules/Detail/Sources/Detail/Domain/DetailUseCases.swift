import Restaurant
import SantapCore

public typealias GetRestaurantDetailUseCase = any UseCase<String, RestaurantDetailModel>
public typealias GetFavoriteStateUseCase = any UseCase<String, Bool>
public typealias UpdateFavoriteUseCase = any UseCase<FavoriteUpdate, Bool>
