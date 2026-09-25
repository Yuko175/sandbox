use crate::users::UserCollection;

mod users;

fn main() {
    let users = UserCollection::new();
    let mut iterator = users.iter();

    for _ in 0..=users.len() {
        let element = iterator.next();
        let index = iterator.index();
        println!("{index} 番目の要素: {element:?}");
    }

    print!("\nユーザーコレクションのすべての要素: ");
    users.iter().for_each(|e| print!("{} ", e));

    println!();
}
