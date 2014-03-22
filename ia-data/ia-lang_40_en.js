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

(function(){
    
	messages.availableLocales.push('en');
    
	messages.screens['en']={
		'control_screen_military_specialities':true
	}
    
	messages['en']={
		'common.clickToHide':'click to hide',
		'common.dblclickToHide':'double click to hide',
		'common.close':'CLOSE',
		
		'menu.close':'CLOSE MENU',
		'menu.exportList':'EXPORT',
		'menu.printList':'PRINT',
		'menu.clearList':'CLEAR',
		'menu.newList':'NEW',
		'menu.loadMercs':'LOAD MERCS',
		'menu.loadList':'LOAD',
		'menu.wiki':'WIKI',
		'menu.openConfigWindow':'CONFIG',
		'menu.reloadApp':'RELOAD APP',
		'menu.menuTitle':'MENU',
		'menu.armylistView':'LIST',
		'menu.addModel':'UNITS',
		'menu.unitDetail':'DETAIL',
		'menu.donate':'DONATE',
		'menu.campaignTools':'CAMPAIGN',
		'menu.duplicateCurrentList':"DUPLICATE CURRENT LIST",
		'menu.gameMode':'GAME',
		'menu.listMode':'EDIT LIST',
		
		
		'config.selectRange.showCm':'range unit : cm',
		'config.selectRange.showIn':'range unit : inch',
		'config.saveAndClose':'SAVE AND CLOSE',
		'config.chooseLocale':'language : ',
		'config.combatGroupSize':'combat group size : ',
		'config.currentListConfig':'CURRENT LIST CONFIG',
		'config.pointCap':'point cap : ',
		'config.armyListTouchActionButton.text':'armyList touch action : ',
		'config.armyListTouchActionButton.text.showInfoAndChooser':'show unit selector',
		'config.armyListTouchActionButton.text.showInfo':'show just unit info',  
		'config.modelSelectionModeButton.text':'add unit to list with : ',
		'config.modelSelectionModeButton.text.singleClick':'single click',
		'config.modelSelectionModeButton.text.doubleClick' :'double click',
		'config.chooseWikiLocale':'wiki language : ',
		'config.showListAfterAddButton.text':"show list after adding any model (small screen only)",
		'config.classicCostSwcPositioning.text':"position cost/swc on the right",
		'config.biggerButtons.text':"bigger buttons",
		'config.yes':"yes",
		'config.no':"no",
		'config.viewMode.defaultViewMode':"View mode: default (auto)",
		'config.viewMode.mobileViewMode':"View mode: mobile",
		'config.mainTheme.default_default':"Graphic Theme: default",
		'config.mainTheme.white_default':"Graphic Theme: white",
		'config.mainTheme.default_big':"Graphic Theme: default (big buttons)",
		'config.mainTheme.white_big':"Graphic Theme: white (big buttons)",
		'config.deviceId':"remote storage id : ",
        
        
		'modelinfo.modelInfoTitle':'unit detail',
		'modelinfo.buttons.swapAltp':"show alternate profile",
		'modelinfo.showImages':"show images",
        
		'armylist.warning.remWarning':'need Hacker or TAG to field REMs',
		'armylist.warning.remAutotWarning':'need Hacker or TAG or G: Mnemonica to field Autotool REMs',
		'armylist.warning.tooManyPoints':'too many points spent',
		'armylist.warning.tooManySwc':'too many swc spent',
		'armylist.warning.tooManyModels':'too many',
		'armylist.warning.ltMiscount':'must have exactly one Lt',
		'armylist.warning.tooBigCGroup':'got more than max models in one Combat Group',
		'armylist.warning.tooManyStarModels':'too many ava 1 models',
        
   
		'armylist.listinfo.modelCount':'models',
		'armylist.listinfo.pointsCount':'points',
		'armylist.listinfo.swcCount':'swc',
		'armylist.listinfo.warnings':'warnings',
		'armylist.listinfo.total':'total',
		'armylist.listinfo.max':'max',
		'armylist.listinfo.remaining':'remaining',
        
		'armylist.groups.groupTitle':'Combat Group #',
        
		'armylist.export.warningsTitle':'Warnings: ',
		'armylist.export.openDesc':'open with Aleph Toolbox',
		'armylist.export.directLink':'direct link',
		'armylist.export.closeButton':'CLOSE',
		'armylist.export.previewButton':'PREVIEW',
		'armylist.export.bbcodeButton':'BBCODE (FORUM CODE)',
		'armylist.export.qrcodeButton':'QRCODE',
		'armylist.export.sendMailButton':'E-MAIL',
                
		'armylistsave.backButton':'BACK',
		'armylistsave.deleteListButton':'delete list',
		'armylistsave.headerLabels.factionLogo':'',
		'armylistsave.headerLabels.buttons':'',
		'armylistsave.headerLabels.faction':'faction',
		'armylistsave.headerLabels.pcap':'pcap',
		'armylistsave.headerLabels.modelCount':'models',
		'armylistsave.headerLabels.lastView':'lastView',
		'armylistsave.headerLabels.name':'name',
		'armylistsave.setName':'set list name',
        
		'armylist.buttons.swapGroupButton':"change combat group",
		'armylist.buttons.removeModelButton':"remove from list",
		'armylist.buttons.moveDownButton':"move down",
		'armylist.buttons.moveUpButton':"move up",
		
		'specop.chooseBaseModel':"choose base unit...",   
		'specop.chooseBaseModelLabel':"Base unit : ",  
		'specop.xpCost':"XP spent : ",
		'specop.attrBoostLevel0':" L0",
		'specop.attrBoostLevel1':" L1",
		'specop.attrBoostLevel2':" L2",
		'specop.attrBoostLevel3':" L3",
		'specop.boostableAttrsContainerLabel':"Upgrade stats : ",
		'specop.extraWeaponsContainerLabel':"Weapons : ",
		'specop.extraSpecsContainerLabel':"Skills/Equipment : ",
		'specop.sopFormTitle':"Spec-Ops control screen",
        
		'wiki.buttons.liveWiki':'LIVE WIKI',
		'wiki.buttons.back':'BACK',
		'wiki.disclamerHtml':'<div id="footer"><div class="license" style="text-align: center; vertical-align: middle; width: 60%; margin: auto;">All the data, text, information, graphics or links published in this Web site  are compiled for informative purposes only, for all those persons that might be interested in them  . You can find all in the  official website http://www.infinitythegame.com. The intellectual property rights of the Web site www.infinitythegame.com as well as its contents belong, to CORVUS BELLI or to third parties, for which NON OF THE USERS are authorise to print or in any case store any of its contents other than for private and personal use. To modify, sell, reproduce, distribute, or otherwise use the Material in any way for any public or commercial purpose is prohibited.</div></div>',
    
    
		'units.attribute.name':'name',
		'units.attribute.code':'code',
		'units.attribute.codename':'code',
		'units.attribute.isc':'isc',
		'units.attribute.type':'type',
		'units.attribute.mov':'mov',
		'units.attribute.cc':'cc',
		'units.attribute.bs':'bs',
		'units.attribute.ph':'ph',
		'units.attribute.wip':'wip',
		'units.attribute.arm':'arm',
		'units.attribute.bts':'bts',
		'units.attribute.w':'w',
		'units.attribute.str':'str',
		'units.attribute.ava':'ava',
		'units.attribute.cost':'cost',
		'units.attribute.swc':'swc',
		'units.attribute.spec':'spec',
		'units.attribute.bsw':'bsw',
		'units.attribute.ccw':'ccw',
		'units.attribute.note':'note',
                
		'units.flagicon.irregular':'Irregular',
		'units.flagicon.impetuous':'Impetuous',
		'units.flagicon.frenzy':'Frenzy',
		'units.flagicon.regular':'Regular',
		'units.flagicon.cube':'Cube',
		'units.flagicon.cube2':'Cube 2.0',
        
        
		'print.bgAdvice':'For Internet Explorer/Firefox, background color printing must be turned on in your print options, otherwise the colors of the weapons table won\'t be printed correctly',
        
		'print.buttonLabel.print':'PRINT',
		'print.buttonLabel.qrcode':'show qrcode',
		'print.buttonLabel.profiles':'show model attrs',
		'print.buttonLabel.specs':'show model specs',
		'print.buttonLabel.info':'show list info',
		'print.buttonLabel.models':'show models',
		'print.buttonLabel.aweapons':'show weapon list',
		'print.buttonLabel.mweapons':'show weapons for each model',
		'print.buttonLabel.icons':'show extra icons',
		'print.buttonLabel.depletables':'show depletable weapon/equipment\'s checkboxes',
		'print.buttonLabel.colors':'show colors',
		//        'print.buttonLabel.hiddenList':'TOGGLE HIDDEN LIST',
		'print.buttonLabel.campaignspecs':'show campaign specs',
		'print.buttonLabel.metabooty':'show metachemistry/booty tables',
		'print.buttonLabel.hiddenList':'hidden list',
		'print.buttonLabel.doubleColumn':'double column',
		'print.hiddenList':'hidden list',
        
		'weapons.label.D':'D',
		'weapons.label.B':'B',
		'weapons.label.A':'A',
		'weapons.label.noLabel':' ',
		'weapons.weaponsButtonTitle':"weapons",
        
		'factionChooser.mercenaryMessage':"choose up to 3 factions from which to build your Mercenary Company",
        
		'campaign.militaryspecs.mobilereserve.title':'Mobile Reserve',
		'campaign.militaryspecs.logistics.title':'Logistics',
		'campaign.militaryspecs.support.title':'Support Force',
		'campaign.militaryspecs.psiops.title':'Psi-Ops',
		'campaign.militaryspecs.deployment.title':'Immediate Deployment',
		'campaign.militaryspecs.intelligence.title':'Intelligence',
		'campaign.militaryspecs.ltident.title':'',
        
		'campaign.militaryspecs.mobilereserve.level1.desc':"+5 army points",
		'campaign.militaryspecs.mobilereserve.level2.desc':"+10 army points",
		'campaign.militaryspecs.mobilereserve.level3.desc':"+10 army points",
		'campaign.militaryspecs.mobilereserve.level4.desc':"+15 army points",
		'campaign.militaryspecs.mobilereserve.level2.descTotal':"+15 army points",
		'campaign.militaryspecs.mobilereserve.level3.descTotal':"+25 army points",
		'campaign.militaryspecs.mobilereserve.level4.descTotal':"+40 army points",
		'campaign.militaryspecs.logistics.level1.desc':"+3 to the promotion roll",
		'campaign.militaryspecs.logistics.level2.desc':"+1 swc & +3 to the promotion roll",
		'campaign.militaryspecs.logistics.level3.desc':"+1 swc & +3 to the promotion roll",
		'campaign.militaryspecs.logistics.level4.desc':"+3 to the promotion roll",
		'campaign.militaryspecs.logistics.level2.descTotal':"+1 swc & +6 to the promotion roll",
		'campaign.militaryspecs.logistics.level3.descTotal':"+2 swc & +9 to the promotion roll",
		'campaign.militaryspecs.logistics.level4.descTotal':"+12 to the promotion roll",
		'campaign.militaryspecs.support.level1.desc':"+1 to ava of 1 troop",
		'campaign.militaryspecs.support.level2.desc':"+1 ava of 1 troop (different from the previous level)",
		'campaign.militaryspecs.support.level3.desc':"+1 ava of 1 troop (different from the previous level)",
		'campaign.militaryspecs.support.level4.desc':"all figures with str get +1 point of str (maximum 3)",
		'campaign.militaryspecs.support.level2.descTotal':"+1 ava of 2 different troops",
		'campaign.militaryspecs.support.level3.descTotal':"+1 ava of 3 different troops",
		'campaign.militaryspecs.support.level4.descTotal':"+1 ava of 3 different troops, and all figures with str get +1 point of str (maximum 3)",
		'campaign.militaryspecs.psiops.level1.desc':"+10% higher threshold for retreat!",
		'campaign.militaryspecs.psiops.level2.desc':"+10% higher threshold for retreat!",
		'campaign.militaryspecs.psiops.level3.desc':"+1 mercenary figure without paying cost or swc",
		'campaign.militaryspecs.psiops.level4.desc':"all figures possess the Religious Troop special skill",
		'campaign.militaryspecs.psiops.level2.descTotal':"+20% higher threshold for retreat!",
		'campaign.militaryspecs.psiops.level3.descTotal':"+20% higher threshold for retreat!, and +1 mercenary figure without paying cost or swc",
		'campaign.militaryspecs.psiops.level4.descTotal':"+20% higher threshold for retreat!, all figures possess the Religious Troop special skill, and +1 mercenary figure without paying cost or swc",
		'campaign.militaryspecs.deployment.level1.desc':"+3 to the initiative roll",
		'campaign.militaryspecs.deployment.level2.desc':"+3 to the initiative roll",
		'campaign.militaryspecs.deployment.level3.desc':"choose side of the table",
		'campaign.militaryspecs.deployment.level4.desc':"initiative and deployment automatically won",
		'campaign.militaryspecs.deployment.level2.descTotal':"+6 to the initiative roll",
		'campaign.militaryspecs.deployment.level3.descTotal':"+6 to the initiative roll, and choose side of the table",
		'campaign.militaryspecs.deployment.level4.descTotal':"initiative and deployment automatically won",
		'campaign.militaryspecs.intelligence.level1.desc':"to know whether the opponent has airborne deployment",
		'campaign.militaryspecs.intelligence.level2.desc':"to know wether the opponent has holoprojector L1, impersonation or hidden deployment",
		'campaign.militaryspecs.intelligence.level3.desc':"to know the opponent's army list",
		'campaign.militaryspecs.intelligence.level4.desc':"to have an alternative army list",
		'campaign.militaryspecs.intelligence.level2.descTotal':"to know wether the opponent has airborne deployment, holoprojector L1, impersonation or hidden deployment",
		'campaign.militaryspecs.intelligence.level3.descTotal':"to know the opponent's army list",
		'campaign.militaryspecs.intelligence.level4.descTotal':"to know the opponent's army list, and to have an alternative army list",        
		'campaign.militaryspecs.ltident.level5.desc':"enemy lieutenant always identified",
	
		'campaign.militaryspecs.level1.label':"Level 1 (2 XP)",
		'campaign.militaryspecs.level2.label':"Level 2 (5 XP)",
		'campaign.militaryspecs.level3.label':"Level 3 (9 XP)",
		'campaign.militaryspecs.level4.label':"Level 4 (14 XP)",
		'campaign.militaryspecs.level5.label':"Level 5 (20 XP)",
        
		'campaign.militaryspecs.level1.title':"L1",
		'campaign.militaryspecs.level2.title':"L2",
		'campaign.militaryspecs.level3.title':"L3",
		'campaign.militaryspecs.level4.title':"L4",
		'campaign.militaryspecs.level5.title':"L5",
        
		'campaign.totalXpCost':"total XP spent : ",
		'campaign.enabled.label':"campaign mode enabled",
		'campaign.disabled.label':"campaign mode disabled",
		'campaign.specsprint.title':"Military Specialities (Paradiso Campaign)",
        
		'game.remainingOrders':"orders: ",
		'game.remainingPoints':"points alive: ",
		'game.lossPercentage':"loss percentage: ",
		'game.retreatWarning':"retreat!",
		'game.photoFileInput.tooltip':"load game field photo/scheme",
		'game.buttons.addPhotoIcon':"put icon on the game field",
		'game.buttons.active':"mark model as active",
		'game.buttons.dead':"mark model as unconscious/dead"
	};
    
	names['en']={
		'isc':{  
			'Gui Feng Spec-Ops':'Guǐ Fēng Spec-Ops',
			'Metros':"Métros",
			'Senor Massacre':"Señor Massacre",
			'Bakunin Uberfallkommando : Chimera':'Bakunin Überfallkommando : Chimera',
			'Bakunin Uberfallkommando : Pupniks':'Bakunin Überfallkommando : Pupniks',
			'Kazak Doktor':'Kazak Dóktor',
			'Phoneix':'Phoenix',
			'Uxia McNeill':'Uxìa McNeill',
			'Margot Berthnier, Mirage-5':'Margot Berthier, Mirage-5',
			'Su-Jian Immediate Action Unit (COMBAT FORM)':'Su-Jian Immediate Action Unit',
			'Throakitai':'Thorakitai',
			'Moderators from Bakunin':'Moderators',
            "Shavastii Seed-Soldiers":"Shasvastii Seed-Soldiers"
		},
		'name':{
			'Phoneix':'Phoenix',
			'Throakites':'Thorakites'
		},
		'codename':{
			'Default':' '
		},
		'bsw':{
		},
		'ccw':{
		},
		'spec':{
		},
		'type':{
		},
		"faction" : {
			"Shavastii Expeditionary Force" : "Shasvastii Expeditionary Force"
		}
	};
    
}());