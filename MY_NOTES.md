...


Right, so we now have to have to add a lifespan to each square such that when one dies, another one appears. 

First thing I'm considering is adding a random lifespan to each square at inception: self.lifespan = random.randint(x, y)

I have to make it so if a certain variable (time passed) equals self.lifespan, the square ceases to exist (ie, it stops getting drawn). 

We already have dt, so we can do certain_variable = 0 then while running: certain_variable += dt and then when certain_variable >= lifespan, RIP 🪦

After RIP, I remove that square from the list and immediately append a new instance of Square() to the list. Rebirth!


Chase Feature:
We already have the flee feature, now we have to make the bigger squares "chase" down the smaller ones. 

My first instinct is to just do the reverse of compute_flee_vector...