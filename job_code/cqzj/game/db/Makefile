####################################################################
## @author QingliangCn <qing.liang.cn@gmail.com>
## @datetime 2010-05-30
## @description beam文件被放在ebin下或者ebin子目录下，所以启动时要
##				注意-pa参数是否设置正确
##
####################################################################

##指定当前项目在svn仓库中的名字
APP_NAME := db
SRC_DIRS := src/*.erl src/mod/*.erl
include ../../../hrl/include.mk

$(EBIN_DIR)/%.$(EMULATOR): $(hrl) src/%.erl 
	$(ERLC) $(ERLC_FLAGS) -o $(EBIN_DIR) $<
	
$(EBIN_DIR)/%.$(EMULATOR): $(hrl) src/mod/%.erl 	
	$(ERLC) $(ERLC_FLAGS) -o $(EBIN_DIR) $<