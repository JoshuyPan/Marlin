module marlin::marlin{

    // ERRORS
    #[error]
    const NOT_DRAGON_OWNER: u64 = 1;
    #[error]
    const NO_DRINKS_FOUND: u64 = 2;
    #[error]
    const DRAGON_SLEEPING: u64 = 3;
    #[error]
    const NOT_THE_ADMIN: u64 = 4;
    #[error]
    const NO_WHIP_FOUND: u64 = 5;
    #[error]
    const DRAGON_IS_AWAKE: u64 = 6;

    // POLICE

    public struct MarlinPolice has key {
        id: UID,
        marlinAdmin: address   
    }
    
    // ASSETS

    public struct Dragon has key, store {
        id: UID,
        name: vector<u8>,
        owner: address,
        health: u64,
        energy: u64,
        level: u64,
        isSleeping: bool
    }

    public struct DragonFood has key, store {
        id: UID,
        name: vector<u8>,
        incrementLevel: u64,
        owner: address
    }

    public struct DragonWhip has key, store {
        id: UID,
        name: vector<u8>,
        owner: address
    }

    // EVENTS
    public struct DragonCreatedEvent has store, copy, drop {
        dragonName: vector<u8>,
        dragonOwner: address
    }
    
    fun init(ctx: &mut TxContext) {
        transfer::share_object(MarlinPolice{
            id: object::new(ctx),
            marlinAdmin: tx_context::sender(ctx)
        })
    }

    public entry fun adoptDragon(
        dragonName: vector<u8>,
        ctx: &mut TxContext
    ){
        //caller of the function
        let sender = tx_context::sender(ctx);

        let dragon = Dragon{
            id: object::new(ctx),
            name: dragonName,
            owner: sender,
            health: 500,
            energy: 100,
            level: 1,
            isSleeping: false
        };

        transfer::transfer(dragon, sender);

        let dragonCreatedEvent = DragonCreatedEvent{
            dragonName: dragonName,
            dragonOwner: sender
        };

        0x2::event::emit<DragonCreatedEvent>(dragonCreatedEvent);
    }

    public entry fun buyDrink(
        dragon: &mut Dragon,
        ctx: &mut TxContext
    ){
        let sender = tx_context::sender(ctx);
        assert!(sender == dragon.owner, NOT_DRAGON_OWNER);
        
        let drink = DragonFood{
            id: object::new(ctx),
            name: b"Uni Juice 1.0",
            incrementLevel: 1,
            owner: sender
        };

        sui::dynamic_object_field::add(&mut dragon.id, drink.name, drink);
    }

    public entry fun buyWhip(
        dragon: &mut Dragon,
        ctx: &mut TxContext
    ){
        let sender = tx_context::sender(ctx);
        assert!(dragon.owner == sender, NOT_DRAGON_OWNER);

        let whip = DragonWhip{
            id: object::new(ctx),
            name: b"Whip",
            owner: sender
        };

        sui::dynamic_object_field::add(&mut dragon.id, whip.name, whip);
    }

    public entry fun feedDragon(
        dragon: &mut Dragon,
        ctx: &mut TxContext
    ){
        let sender = tx_context::sender(ctx);
        assert!(dragon.owner == sender, NOT_DRAGON_OWNER);
        assert!(dragon.isSleeping == false, DRAGON_SLEEPING);
        let name = b"Uni Juice 1.0";
        let haveDrink = sui::dynamic_object_field::exists_(&mut dragon.id, name);
        assert!(haveDrink, NO_DRINKS_FOUND);

        let drink = sui::dynamic_object_field::borrow_mut<vector<u8>, DragonFood>(&mut dragon.id, name);
        dragon.level = dragon.level + drink.incrementLevel;
        
        let DragonFood {
            id,
            name: _,
            incrementLevel: _,
            owner: _
        } = sui::dynamic_object_field::remove(&mut dragon.id, name);
        object::delete(id);
    }

    public entry fun ipnotizeDragon(
        police: &MarlinPolice,
        dragon: &mut Dragon,
        ctx: &mut TxContext
    ){
        let sender = tx_context::sender(ctx);
        assert!(sender == police.marlinAdmin, NOT_THE_ADMIN);

        dragon.isSleeping = true;
    }
    
    public entry fun wakeUp(
        dragon: &mut Dragon,
        ctx: &mut TxContext
    ){
        let sender = tx_context::sender(ctx);
        assert!(sender == dragon.owner, NOT_DRAGON_OWNER);
        assert!(dragon.isSleeping == true, DRAGON_IS_AWAKE);
        let name = b"Whip";
        let haveWhip = sui::dynamic_object_field::exists_(&mut dragon.id, name);
        assert!(haveWhip, NO_WHIP_FOUND);

        let DragonWhip {
            id,
            name: _,
            owner: _
        } = sui::dynamic_object_field::remove(&mut dragon.id, name);
        object::delete(id);

        dragon.isSleeping = false;
    }

    
}