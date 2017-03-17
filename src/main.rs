struct Resolution {
    x: u32,
    y: u32,
}

#[derive(Debug)]
struct Pixel {
    distance: f64,
    wall_height: u32,
    x: f64,
    y: f64,
}

fn main() {
    let map = [
        [1,0,1,1,1,1,1,1,1,1],
        [1,0,1,0,0,0,0,0,0,1],
        [1,0,0,0,1,0,0,0,0,1],
        [1,1,0,1,1,0,0,0,0,1],
        [1,0,0,0,1,1,1,1,0,1],
        [1,0,0,0,1,0,0,0,0,1],
        [1,0,1,0,1,0,0,0,0,1],
        [1,0,0,0,1,0,1,1,1,1],
        [1,0,0,0,1,0,0,0,0,0],
        [1,1,1,1,1,1,1,1,0,1],
    ];
    let window = Resolution { x: 1280, y: 960 };
    let resolution = Resolution { x: 160, y: 120 };
    let column_spacing = window.x / resolution.x;
    let row_spacing = window.y / resolution.y;
    let range = 10;
    let focal_length = 0.8;

    let mut angles: Vec<f64> = Vec::with_capacity(resolution.x as usize);
    let mut pixels: Vec<Pixel> = Vec::new();
    calculate(&mut angles, &mut pixels, &resolution, &focal_length);

    println!("{:?}", angles.len());
    println!("{:?}", angles);
    println!("{:?}", pixels.len());
    println!("{:?}", pixels);
}

fn calculate(angles: &mut Vec<f64>, pixels: &mut Vec<Pixel>, resolution: &Resolution, focal_length: &f64) {
    let mid = resolution.x / 2;
    for column in 0..resolution.x {
        let x_scaled = column as f64 / resolution.x as f64 - 0.5;
        let relative_angle = x_scaled.atan2(*focal_length);
        angles.push(relative_angle);
        for row in mid..resolution.y {
            let wall_height = 2 * (row - mid);
            // if wall_height <= 0 { continue; }
            let relative_y = -(resolution.y as f64 / wall_height as f64);
            let distance = -(relative_y as f64 / relative_angle.cos());
            let relative_x = distance * relative_angle.sin();
            pixels.push(Pixel {
                distance: distance, wall_height: wall_height, x: relative_x, y: relative_y
            });
        }
    }
}
