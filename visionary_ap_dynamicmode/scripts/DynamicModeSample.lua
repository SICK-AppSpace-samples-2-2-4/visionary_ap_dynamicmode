--[[----------------------------------------------------------------------------

  Implementing dynamic mode by filtering pixels changed more than a certain threshold
  between two images.
  
------------------------------------------------------------------------------]]

-- Setup camera
local camera = Image.Provider.Camera.create()
camera:stop()

-- If a pixel differs more than this threshold between two images, the pixel is removed.
local THRESHOLD = 100

local deco = View.ImageDecoration.create()
deco:setRange(0, 10000)
local v = View.create('2DViewer')

local previousImage = nil

--Declaration of the 'main' function as an entry point for the event loop
--@main()
local function main()
  Image.Provider.Camera.start(camera)
end
--The following registration is part of the global scope which runs once after startup
--Registration of the 'main' function to the 'Engine.OnStarted' event
Script.register('Engine.OnStarted', main)

--@dynamicFilter(image:Image)
local function dynamicFilter(image)
  -- Store the datatype of the pixel
  local originalType = Image.getType(image)
  -- Convert the image to float32
  local currentImage = Image.toType(image, 'FLOAT32')
  -- Ignore missing data
  currentImage:setMissingDataFlag(false)
  local result
  if previousImage then
    -- Calcute the absolute of the difference image
    local diffImg = Image.abs(Image.subtract(currentImage, previousImage))
    -- Find all pixels that are above threshold
    local region = Image.threshold(diffImg, THRESHOLD)
    -- Set all found pixels to 0
    local filteredImage = Image.PixelRegion.fillRegion(region, 0, currentImage)
    -- Set the image type to the type of the stored image
    result = Image.toType(filteredImage, originalType)
  else
    result = image
  end
  -- Store the most recent image to use it as the last image in the next iteration
  previousImage = currentImage

  return result
end

--@handleOnNewImage(image:Image,_:SensorData)
local function handleOnNewImage(image, _)
  local img = dynamicFilter(image[1])
  View.addImage(v, img, deco)
  View.present(v)
end
-- Registration of the 'handleOnNewImage' function to the cameras "OnNewImage" event
Image.Provider.Camera.register(camera, 'OnNewImage', handleOnNewImage)
