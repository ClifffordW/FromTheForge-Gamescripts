return {
  version = "1.5",
  luaversion = "5.1",
  tiledversion = "1.7.2",
  orientation = "orthogonal",
  renderorder = "right-down",
  width = 23,
  height = 15,
  tilewidth = 64,
  tileheight = 64,
  nextlayerid = 4,
  nextobjectid = 4,
  properties = {},
  tilesets = {
    {
      name = "startingforest",
      firstgid = 1,
      filename = "../../../../../../contentsrc/levels/TileGroups/startingforest.tsx"
    }
  },
  layers = {
    {
      type = "tilelayer",
      x = 0,
      y = 0,
      width = 23,
      height = 15,
      id = 1,
      name = "BG_TILES",
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      parallaxx = 1,
      parallaxy = 1,
      properties = {},
      encoding = "lua",
      data = {
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 3, 3, 6, 6, 6, 6, 6, 6, 3, 3, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 2, 3, 6, 6, 6, 6, 6, 6, 3, 2, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 2, 2, 2, 2, 3, 6, 6, 6, 6, 6, 6, 3, 2, 2, 2, 2, 0, 0, 0,
        0, 0, 0, 0, 2, 2, 2, 2, 3, 6, 6, 6, 6, 6, 6, 3, 2, 2, 2, 2, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 2, 3, 6, 6, 6, 6, 6, 6, 3, 2, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 3, 3, 6, 6, 6, 6, 6, 6, 3, 3, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
      }
    },
    {
      type = "objectgroup",
      draworder = "topdown",
      id = 2,
      name = "PORTALS",
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      parallaxx = 1,
      parallaxy = 1,
      properties = {},
      objects = {
        {
          id = 1,
          name = "",
          type = "room_portal",
          shape = "rectangle",
          x = 1088.99,
          y = 440.335,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {
            ["roomportal.cardinal"] = "east"
          }
        },
        {
          id = 2,
          name = "",
          type = "room_portal",
          shape = "rectangle",
          x = 768.248,
          y = 702.251,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {
            ["roomportal.cardinal"] = "south"
          }
        },
        {
          id = 3,
          name = "",
          type = "room_portal",
          shape = "rectangle",
          x = 443.333,
          y = 443.333,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {
            ["roomportal.cardinal"] = "west"
          }
        }
      }
    }
  }
}
