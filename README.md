# Gluon 

## Abstract
Gluon is a set of pllua function to power a rules engine for postgresql hstore.
The main goal of Gluon is to offer a lightweight and efficient solution to write flawlessly complex business rules.

A rule is designed by its input and output keys and is written in lua. 
With rule's metadata, Gluon is able to resolve which rules must be executed in a given situation and offers a way to implement business rules without bothering with anything than essential good business code.

Gluon actually implements 2 main features:
  - rule solver: triggers the good rule at the good moment.
  - rule runner: executes the rule and provides results

Gluon is designed to run within a postgresql database supporting key/value hstore type. Its design permits to anybody to write rules.

# Installation
Once you retrieved the main archive from github, unzip and run the deploy.sql script.
Be aware that this script will create the following objects in the target database:
- schema pllua: created by pllua extension.
- schema gluon: created by the script, gluon itself.
- schema public: hstore functions created by the hstore extension.

# Usage
## write rule
Nothing for the moment, update the rule table.
-- Fixme: just work on it. :)

## execute rule
select gluon.exec(array['wanted_1'], given_hstore)
-- Fixme: srsly, is that a manual ?

## solve rules
select gluon.solve(array['wanted_1', 'wanted_2']) will return all the information necessary to gain access to the wanted_1 value. 
-- Fixme: give more information on input and ouput streams.

# Dependencies
Postgres 9.0+ with hstore extension and pllua extension.
Lua 5.2+

# Changetable:
- v0.1: First kit, elementary functionnalities are present, probably a lot of bugs, beware. See you soon.

# Roadmap:
v0.2: 
- regexp/rule support in switches
- advanced tools to solve conflicts and debug rules execution
- unit testing module
- design and develop CLI and GUI
- pure lua solver and player.
