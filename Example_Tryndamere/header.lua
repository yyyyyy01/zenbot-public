return {
    id = "Example_Tryndamere", -- Internal name of your script, avoid using spaces or any super special characters
    name = "Exmpl Tryndamere", -- public name, that will show up in external scripts list
    load = function()
        return ({ -- here you can provide a table with list of champions that the script will be active on, I'll leave the rest as an example
            Tryndamere = true,
            --[[Chogath = true,
            Zilean = true,
            Kayle = true,
            Veigar = true]]
        })[player.charName]
    end,
}
