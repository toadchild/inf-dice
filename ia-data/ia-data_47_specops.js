/*
	This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

data.specops={
    specopsisc:{
        'Panoceania':'Indigo Spec-Ops',
        'Combined Army':'Corax/Treitak Spec-Ops',
//        'Shavastii Expeditionary Force':'Corax Spec-Ops',
//        'Morat Aggression Force':'Treitak Spec-Ops',
        'Aleph':"Chandra Spec-Ops",
        'Ariadna':"Intel Spec-Ops",
        'Haqqislam':"Husam Spec-Ops",
        'Nomads':"Vortex Spec-Ops",
        'Tohaa':"Hatail Spec-Ops",
        'Yu Jing':"Gui Feng Spec-Ops"
    },
    basemodels:{
        'Panoceania':[{
            isc:'Fusiliers',
            code:'Default'
        },{
            isc:'Acontecimento Regulars',
            code:'Default'
        },{
            isc:'Order Sergeants',
            code:'Default'
        }],
        'Combined Army':[{
            isc:'Shavastii Seed-Soldiers',
            code:'Default'
        },{
            isc:'Morat Vanguard Infantry',
            code:'Default'
        }],
//        'Morat Aggression Force':[{
//            isc:'Morat Vanguard Infantry',
//            code:'Default'
//        }],
//        'Shavastii Expeditionary Force':[{
//            isc:'Shavastii Seed-Soldiers',
//            code:'Default'
//        }],
        'Aleph':[{
            isc:'Throakitai',
            code:'combi'
        }],
        'Ariadna':[{
            isc:'Line Kazak',
            code:'Default'
        },{
            isc:'Caledonian Volunteers',
            code:'Default'
        },{
            isc:'Metros',
            code:'Default'
        }],
        'Haqqislam':[{
            isc:'Ghulam',
            code:'Default'
        },{
            isc:'Hassassin Muyibs',
            code:'Panzerfaust'
        },{
            isc:'Hafza Unit',
            code:'Default'
        }],
        'Nomads':[{
            isc:'Alguaciles',
            code:'Default'
        },{
            isc:'Moderators from Bakunin',
            code:'Default'
        }],
        'Tohaa':[{
            isc:'Kamael Light Infantry',
            code:'Default'
        }],
        'Yu Jing':[{
            isc:'Keisotsu',
            code:'Default'
        },{
            isc:'Zhanshi',
            code:'Default'
        },{
            isc:'Celestial Guard',
            code:'Default'
        }]
    },
    attributeboost:{
        cc:[2,3,5],
        bs:[1,1,1],
        ph:[1,2,0],
        wip:[1,2,3],
        arm:[0,1,2],
        bts:[-3,-3,-3],
        w:[0,0,1]
    },
    attributeboostcost:[2,3,5],
    attributeboostmax:{
        wip:15,
        ph:14,
        w:2
    },
    extraweapons:{
        'Panoceania':{
            'AP CCW':1,
            'EXP CCW':1,
            'Stun Pistol':1,
            'Boarding Shotgun':2,
            'Grenades':2,
            'Assault Pistol':3,
            'Nanopulser':3,
            'Contender':4,
            'MULTI Rifle':5,
            'MULTI Sniper Rifle':6,
            'Spitfire':6,
            'HMG':8
        },
        'Yu Jing':{
            'AP CCW':1,
            'EXP CCW':1,
            'Stun Pistol':1,
            'Boarding Shotgun':2,
            'Grenades':2,
            'Assault Pistol':3,
            'Nanopulser':3,
            'Contender':4,
            'MULTI Rifle':5,
            'MULTI Sniper Rifle':6,
            'Spitfire':6,
            'HMG':8
        },
        'Nomads':{
            'AP CCW':1,
            'EXP CCW':1,
            'Stun Pistol':1,
            'Boarding Shotgun':2,
            'Grenades':2,
            'Assault Pistol':3,
            'Nanopulser':3,
            'Contender':4,
            'MULTI Rifle':5,
            'MULTI Sniper Rifle':6,
            'Spitfire':6,
            'HMG':8
        },
        'Aleph':{
            'AP CCW':1,
            'EXP CCW':1,
            'Stun Pistol':1,
            'Boarding Shotgun':2,
            'Grenades':2,
            'Assault Pistol':3,
            'Nanopulser':3,
            'Contender':4,
            'MULTI Rifle':5,
            'MULTI Sniper Rifle':6,
            'Spitfire':6,
            'HMG':8
        },
        'Ariadna':{
            'AP CCW':1,
            'Stun Pistol':1,
            'Chain Rifle':2,
            'Boarding Shotgun':2,
            'Adhesive Launcher':3,
            'Grenades':3,
            'Panzerfaust':4,
            'AP Sniper Rifle':5,
            'T2 Rifle':5,
            'Molotok':6,
            'HMG':8,
            'AP HMG':9
        },
        'Haqqislam':{
            'EXP CCW':1,
            'Viral CCW':1,
            'Stun Pistol':1,
            'Boarding Shotgun':2,
            'Grenades':3,
            'Nanopulser':3,
            'Contender':4,
            'Panzerfaust':4,
            'Viral Rifle':5,
            'Viral Sniper Rifle':6,
            'Spitfire':6,
            'HMG':8
        },
        'Combined Army':{
            'EXP CCW':1,
            'Stun Pistol':1,
            'Monofilament CCW':2,
            'Boarding Shotgun':2,
            'Grenades':3,
            'Nanopulser':3,
            'Contender':4,
            'MULTI Rifle':5,
            'MULTI Sniper Rifle':6,
            'Plasma Rifle':6,
            'Spitfire':6,
            'HMG':8
        },
        'Tohaa':{
            'Viral CCW':1,
            'Stun Pistol':1,
            'Vulkan Shotgun':3,
            'Adhesive Launcher':3,
            'Nanopulser':3,
            'Flammenspeer':4,
            'Swarm Grenades':4,
            'Heavy Flamethrower':4,
            'Viral Combi Rifle':5,
            'Sniper Rifle':5,
            'Spitfire':6,
            'HMG':8
        }
    },
    extraspecs:{
        'Specialist Troop':1,
        'Doctor':2,
        'Engineer':2,
        'Hyper-Dynamics L1':2,
        'Martial Arts L3':2,
        'MEDEVAC +1':2,
        'Minelayer':2,
        'Natural Born Warrior':2,
        'Climbing Plus':3,
        'CUBEVAC +1':3,
        'Hyper-Dynamics L2':3,
        'Martial Arts L4':3,
        'CH: Mimetism':4,
        'Inferior Infiltration':4,
        'Martial Arts L5':4,
        'Religious Troop':4,
        'Super-Jump':4,
        'Hyper-Dynamics L3':5,
        'AD: Inferior Combat Jump':6,
        'Chain of Command':8,
        'Infiltration':8,
        'V: No Wound Incapacitation':8,
        'Regeneration':8,
        'Sapper':8,
        'Hacker (Hacking Device)':2,
        'Cube':2,
        'Holoprojector L1':3,
        'Holoprojector L2':5,
        'AutoMediKit':6
    }
}
