Generate a canvas.

  $ dune exec ../bin/main.exe ../examples/canvas.pic canvas.svg
  $ cat canvas.svg
  <svg xmlns='http://www.w3.org/2000/svg' width='500' height='300' viewBox = '0 0 500 300'><rect x='0' y ='0' width ='500' height ='300' fill ='#277da1' /></svg>


No background

  $ dune exec ../bin/main.exe ../examples/blank_background.pic canvas2.svg
  $ cat canvas2.svg
  <svg xmlns='http://www.w3.org/2000/svg' width='300' height='400' viewBox = '0 0 300 400'></svg>

Test multiple shapes that overlap
  $ dune exec ../bin/main.exe ../examples/multiple_shapes.pic canvas2.svg
  $ cat canvas2.svg
  <svg xmlns='http://www.w3.org/2000/svg' width='500' height='300' viewBox = '0 0 500 300'><rect x='0' y ='0' width ='500' height ='300' fill ='#091226' /> <circle cx='250' cy='150' r='90' fill = '#d9a441' /> <rect x='250' y='150' width =
      '120' height ='60' fill ='#fff1b0' />  <circle cx='0' cy='0' r='200' fill = '#277da1' />  <circle cx='0' cy='0' r='100' fill = '#FF0000' /> </svg>

Test negative numbers for shapes
  $ dune exec ../bin/main.exe -- ../examples/taks2_tests/negative_nums.pic canvas.svg
  $ cat canvas.svg
  Error

Create a valid picture file with a canvas and shapes:
  $ cat > shapes.pic << 'EOF'
  > canvas 500 300 blue
  > circle 250 150 90 gold
  > rectangle 10 10 100 50 red
  > line 0 0 100 100 white 5
  > EOF

Run the generator:
  $ ../../bin/main.exe shapes.pic shapes.svg

Verify the generated SVG output:
  $ cat shapes.svg
  <svg xmlns='http://www.w3.org/2000/svg' width='500' height='300' viewBox = '0 0 500 300'><rect x='0' y ='0' width ='500' height ='300' fill ='#277da1' /> <circle cx='250' cy='150' r='90' fill = '#d9a441' /> <rect x='10' y='10' width =
      '100' height ='50' fill ='#c1121f' /> <line x1='0' y1 ='0' x2 ='100' y2 = '100' stroke ='#ffffff' stroke-width = '5' />  </svg>

Create a picture file with text contents:
  $ cat > text.pic << 'EOF'
  > canvas 400 200 black
  > text 200 100 24 cream Hello World
  > EOF

Run the generator:
  $ ../../bin/main.exe text.pic text.svg

Verify the generated SVG output:
  $ cat text.svg
  <svg xmlns='http://www.w3.org/2000/svg' width='400' height='200' viewBox = '0 0 400 200'><rect x='0' y ='0' width ='400' height ='200' fill ='#111111' /><text x='200' y='100' font-family= 'sans-serif' font-size = '42' text-anchor = 'middle' fill ='#fff1b0'>  Hello World</text> </svg>

